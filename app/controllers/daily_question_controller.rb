# frozen_string_literal: true

class DailyQuestionController < ApplicationController
  before_action :authenticate_user!

  # GET /daily_question
  # Returns today's question with choices, whether the user already answered,
  # and team stats (how many answered, how many got it right).
  def show
    book_list = @current_user.team.book_list
    unless book_list
      render json: { available: false }
      return
    end

    question = pick_question(book_list)
    unless question
      render json: { available: false }
      return
    end

    choices = book_list.book_list_items.order(:position).map do |item|
      { id: item.id, title: item.title, author: item.author }
    end

    my_answer = DailyQuestionAnswer.find_by(user_id: @current_user.id, answer_date: Date.current)
    team_user_ids = @current_user.team.users.pluck(:id)
    team_answers = DailyQuestionAnswer.where(user_id: team_user_ids, answer_date: Date.current, quiz_question_id: question.id)
    team_answered_count = team_answers.count
    team_correct_count = team_answers.where(correct: true).count

    payload = {
      available: true,
      question_id: question.id,
      question_text: question.question_text,
      choices: choices,
      team_answered: team_answered_count,
      team_correct: team_correct_count
    }

    if my_answer
      payload[:already_answered] = true
      payload[:my_choice_id] = my_answer.chosen_book_list_item_id
      payload[:correct] = my_answer.correct
      payload[:correct_answer_id] = question.correct_book_list_item_id
    else
      payload[:already_answered] = false
    end

    render json: payload
  end

  # POST /daily_question/answer
  # Records the user's answer for today. Params: { book_list_item_id: ... }
  def answer
    book_list = @current_user.team.book_list
    unless book_list
      render json: { errors: ['Team has no book list'] }, status: :unprocessable_entity
      return
    end

    question = pick_question(book_list)
    unless question
      render json: { errors: ['No question available today'] }, status: :unprocessable_entity
      return
    end

    existing = DailyQuestionAnswer.find_by(user_id: @current_user.id, answer_date: Date.current)
    if existing
      render json: { errors: ['You already answered today'] }, status: :unprocessable_entity
      return
    end

    chosen_item = book_list.book_list_items.find_by(id: params[:book_list_item_id])
    unless chosen_item
      render json: { errors: ['Invalid choice'] }, status: :unprocessable_entity
      return
    end

    correct = chosen_item.id == question.correct_book_list_item_id

    DailyQuestionAnswer.create!(
      user: @current_user,
      answer_date: Date.current,
      quiz_question: question,
      chosen_book_list_item: chosen_item,
      correct: correct
    )

    @current_user.log_activity!

    team_user_ids = @current_user.team.users.pluck(:id)
    team_answers = DailyQuestionAnswer.where(user_id: team_user_ids, answer_date: Date.current, quiz_question_id: question.id)

    render json: {
      correct: correct,
      correct_answer_id: question.correct_book_list_item_id,
      team_answered: team_answers.count,
      team_correct: team_answers.where(correct: true).count
    }
  end

  private

  # Deterministically pick a question for today based on team + date.
  # Uses a hash of (team_id + date) as a seed so the whole team sees the same question.
  def pick_question(book_list)
    questions = book_list.quiz_questions.order(:id).to_a
    return nil if questions.empty?

    seed = Digest::MD5.hexdigest("#{@current_user.team_id}-#{Date.current.iso8601}").to_i(16)
    questions[seed % questions.length]
  end
end
