# frozen_string_literal: true

class QuizMatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz_match, only: [:show, :join, :answer, :timeout, :decline]
  before_action :authorize_participant!, only: [:show, :join, :answer, :timeout, :decline]

  def history
    matches = QuizMatch
      .for_user(@current_user)
      .where(status: :completed)
      .order(created_at: :desc)
      .limit(50)
      .includes(:challenger, :opponent, :invited_opponent)

    render json: matches.map { |m| QuizMatchPayloadBuilder.build(m).merge(created_at: m.created_at.iso8601) }
  end

  def challengeable_teammates
    teammates = @current_user.team.teammates.where.not(id: @current_user.id).order(:username)
    online_ids = PresenceTracker.online_user_ids(@current_user.team_id)
    render json: teammates.map { |u| { id: u.id, username: u.username, avatar_emoji: u.avatar_emoji, online: online_ids.include?(u.id) } }
  end

  def pending_invite
    match = QuizMatch.pending_for_opponent(@current_user).order(created_at: :desc).first
    if match
      render json: QuizMatchPayloadBuilder.build(match)
    else
      render json: nil
    end
  end

  def create
    opponent = @current_user.team.teammates.find_by(id: params[:opponent_id])
    unless opponent
      render json: { errors: ['Opponent not found or not a teammate'] }, status: :unprocessable_entity
      return
    end

    if opponent.id == @current_user.id
      render json: { errors: ['You cannot challenge yourself'] }, status: :unprocessable_entity
      return
    end

    book_list = @current_user.team.book_list
    unless book_list
      render json: { errors: ['Team has no book list selected'] }, status: :unprocessable_entity
      return
    end

    questions_payload = QuizMatchQuestionBuilder.build(
      challenger: @current_user,
      opponent: opponent,
      book_list: book_list
    )

    if questions_payload.size != QuizMatch::QUESTIONS_COUNT
      render json: { errors: ['Not enough quiz questions available for this book list'] }, status: :unprocessable_entity
      return
    end

    match = QuizMatch.create!(
      challenger: @current_user,
      invited_opponent: opponent,
      team: @current_user.team,
      book_list: book_list,
      status: :pending,
      phase: :waiting_opponent,
      questions_payload: questions_payload
    )

    @current_user.log_activity!
    broadcast_match_state(match)
    render json: QuizMatchPayloadBuilder.build(match), status: :created
  end

  def join
    unless @quiz_match.status_pending? && @quiz_match.invited_opponent_id == @current_user.id
      render json: { errors: ['You cannot join this match'] }, status: :forbidden
      return
    end

    @quiz_match.update!(
      opponent_id: @current_user.id,
      status: :in_progress,
      phase: :question_show,
      current_question_index: 0,
      phase_entered_at: Time.current
    )

    @current_user.log_activity!
    broadcast_match_state(@quiz_match)
    render json: QuizMatchPayloadBuilder.build(@quiz_match)
  end

  def show
    render json: QuizMatchPayloadBuilder.build(@quiz_match)
  end

  def decline
    unless @quiz_match.status_pending? && @quiz_match.invited_opponent_id == @current_user.id && @quiz_match.opponent_id.nil?
      render json: { errors: ['You cannot decline this match'] }, status: :forbidden
      return
    end

    @quiz_match.update!(status: :cancelled, phase: :completed, phase_entered_at: nil)
    broadcast_match_state(@quiz_match)
    head :no_content
  end

  def answer
    unless @quiz_match.status_in_progress?
      render json: { errors: ['Match is not in progress'] }, status: :unprocessable_entity
      return
    end

    unless @quiz_match.can_answer?(@current_user)
      render json: { errors: ['It is not your turn to answer'] }, status: :forbidden
      return
    end

    question_index = params[:question_index].to_i
    if question_index != @quiz_match.current_question_index
      render json: { errors: ['Wrong question'] }, status: :unprocessable_entity
      return
    end

    question_data = @quiz_match.questions_payload[question_index]
    question = QuizQuestion.find_by(id: question_data['quiz_question_id'])
    unless question && question.book_list_id == @quiz_match.book_list_id
      render json: { errors: ['Question not found'] }, status: :not_found
      return
    end

    steal_ctx = @quiz_match.current_steal_context
    partial_steal = steal_ctx.is_a?(Hash) && steal_ctx['partial_steal'] && steal_ctx['locked_book_list_item_id'].present?

    correct = false
    points = 0

    if @quiz_match.phase == 'question_show'
      # First responder
      book_list_item_id = params[:book_list_item_id].to_i
      author_choice_id = params[:author_choice_id].to_i
      chosen_item = @quiz_match.book_list.book_list_items.find_by(id: book_list_item_id)
      author_item = @quiz_match.book_list.book_list_items.find_by(id: author_choice_id)
      unless chosen_item && author_item
        render json: { errors: ['Invalid book or author choice'] }, status: :unprocessable_entity
        return
      end
      correct_item = question.correct_book_list_item
      title_correct = (chosen_item.id == correct_item.id)
      author_correct = (author_item.author.to_s == correct_item.author.to_s)
      correct = title_correct && author_correct
      points = correct ? QuizMatch::POINTS_PER_CORRECT : 0

      if correct
        add_points!(@current_user.id, points)
        record_question_result!(question: question, first_responder_correct: true, second_responder_correct: nil)
        advance_to_next_question!
      else
        if title_correct && !author_correct
          @quiz_match.update!(
            phase: :second_responder_can_answer,
            phase_entered_at: Time.current,
            current_steal_context: {
              'partial_steal' => true,
              'first_responder_title_correct' => true,
              'locked_book_list_item_id' => correct_item.id
            }
          )
        else
          @quiz_match.update!(
            phase: :second_responder_can_answer,
            phase_entered_at: Time.current,
            current_steal_context: nil
          )
        end
      end
    else
      # Second responder (steal phase)
      if partial_steal
        author_choice_id = params[:author_choice_id].to_i
        author_item = @quiz_match.book_list.book_list_items.find_by(id: author_choice_id)
        locked_id = steal_ctx['locked_book_list_item_id']
        unless author_item && locked_id.present?
          render json: { errors: ['Invalid author choice'] }, status: :unprocessable_entity
          return
        end
        correct_item = question.correct_book_list_item
        author_correct = (author_item.author.to_s == correct_item.author.to_s)
        correct = author_correct
        points = author_correct ? QuizMatch::POINTS_PARTIAL : 0
        first_id = question_data['first_responder_id']
        add_points!(first_id, QuizMatch::POINTS_PARTIAL) if first_id.present?
        if author_correct
          add_points!(@current_user.id, QuizMatch::POINTS_PARTIAL)
          record_question_result!(question: question, first_responder_correct: true, second_responder_correct: true)
        else
          record_question_result!(question: question, first_responder_correct: true, second_responder_correct: false)
        end
        clear_steal_context_and_advance!
      else
        book_list_item_id = params[:book_list_item_id].to_i
        author_choice_id = params[:author_choice_id].to_i
        chosen_item = @quiz_match.book_list.book_list_items.find_by(id: book_list_item_id)
        author_item = @quiz_match.book_list.book_list_items.find_by(id: author_choice_id)
        unless chosen_item && author_item
          render json: { errors: ['Invalid book or author choice'] }, status: :unprocessable_entity
          return
        end
        correct_item = question.correct_book_list_item
        correct = (chosen_item.id == correct_item.id && author_item.author.to_s == correct_item.author.to_s)
        points = correct ? QuizMatch::POINTS_PER_CORRECT : 0
        if correct
          add_points!(@current_user.id, points)
          record_question_result!(question: question, first_responder_correct: false, second_responder_correct: true)
        else
          record_question_result!(question: question, first_responder_correct: false, second_responder_correct: false)
        end
        clear_steal_context_and_advance!
      end
    end

    broadcast_match_state(@quiz_match, last_answer: { correct: correct, respondent_id: @current_user.id, points: points })
    render json: QuizMatchPayloadBuilder.build(@quiz_match).merge(last_answer: { correct: correct, points: points })
  end

  def timeout
    unless @quiz_match.status_in_progress?
      render json: { errors: ['Match is not in progress'] }, status: :unprocessable_entity
      return
    end

    allowed_id = @quiz_match.allowed_responder_id
    unless allowed_id == @current_user.id
      render json: { errors: ['Only the current responder may timeout'] }, status: :forbidden
      return
    end

    if @quiz_match.phase == 'question_show'
      @quiz_match.update!(phase: :second_responder_can_answer, phase_entered_at: Time.current)
    elsif @quiz_match.phase == 'second_responder_can_answer'
      question_data = @quiz_match.current_question_data
      steal_ctx = @quiz_match.current_steal_context
      partial_steal = steal_ctx.is_a?(Hash) && steal_ctx['partial_steal'] && steal_ctx['locked_book_list_item_id'].present?
      if question_data
        q = QuizQuestion.find_by(id: question_data['quiz_question_id'])
        if q
          if partial_steal
            add_points!(question_data['first_responder_id'], QuizMatch::POINTS_PARTIAL) if question_data['first_responder_id'].present?
            record_question_result!(question: q, first_responder_correct: true, second_responder_correct: false)
          else
            record_question_result!(question: q, first_responder_correct: false, second_responder_correct: false)
          end
        end
      end
      @quiz_match.update_column(:current_steal_context, nil)
      advance_to_next_question!
    else
      render json: { errors: ['Timeout not allowed in this phase'] }, status: :unprocessable_entity
      return
    end

    broadcast_match_state(@quiz_match)
    render json: QuizMatchPayloadBuilder.build(@quiz_match)
  end

  private

  def set_quiz_match
    @quiz_match = QuizMatch.for_user(@current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { errors: ['Match not found'] }, status: :not_found
  end

  def authorize_participant!
    return if @quiz_match.participant?(@current_user)

    render json: { errors: ['You are not a participant in this match'] }, status: :forbidden
  end

  def record_question_result!(question:, first_responder_correct:, second_responder_correct:)
    return unless question

    data = @quiz_match.current_question_data
    return unless data

    correct_item = question.correct_book_list_item
    entry = {
      question_index: @quiz_match.current_question_index,
      quiz_question_id: question.id,
      question_text: question.question_text,
      correct_book_title: correct_item&.title,
      correct_book_author: correct_item&.author,
      first_responder_id: data['first_responder_id'],
      first_responder_correct: first_responder_correct,
      second_responder_correct: second_responder_correct
    }
    results = (@quiz_match.question_results || []).dup
    results << entry
    @quiz_match.update_column(:question_results, results)
  end

  def add_points!(user_id, pts)
    return if pts.to_i <= 0

    if user_id == @quiz_match.challenger_id
      @quiz_match.update!(challenger_score: @quiz_match.challenger_score + pts)
    elsif user_id == @quiz_match.opponent_id
      @quiz_match.update!(opponent_score: @quiz_match.opponent_score + pts)
    end
  end

  def clear_steal_context_and_advance!
    @quiz_match.update_column(:current_steal_context, nil)
    advance_to_next_question!
  end

  def advance_to_next_question!
    attrs = { current_steal_context: nil }
    next_index = @quiz_match.current_question_index + 1
    if next_index >= QuizMatch::QUESTIONS_COUNT
      attrs.merge!(
        current_question_index: QuizMatch::QUESTIONS_COUNT - 1,
        status: :completed,
        phase: :completed,
        phase_entered_at: nil
      )
    else
      attrs.merge!(
        current_question_index: next_index,
        phase: :question_show,
        phase_entered_at: Time.current
      )
    end
    @quiz_match.update!(attrs)
  end

  def broadcast_match_state(match, extra = {})
    payload = QuizMatchPayloadBuilder.build(match).merge(extra).stringify_keys
    QuizMatchChannel.broadcast_to(match, payload)
  end
end
