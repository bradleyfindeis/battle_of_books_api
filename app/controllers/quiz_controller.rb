# frozen_string_literal: true

class QuizController < ApplicationController
  before_action :authenticate_user!

  def attempt_start
    book_list_id = params[:book_list_id]
    total_count = params[:total_count].to_i

    book_list = BookList.find_by(id: book_list_id)
    unless book_list
      render json: { errors: ['Book list not found'] }, status: :unprocessable_entity
      return
    end

    question_count = book_list.quiz_questions.count
    expected_totals = [question_count, question_count * 2, 20, 40].uniq
    unless expected_totals.include?(total_count)
      render json: { errors: ["total_count must be one of #{expected_totals.join(', ')}"] }, status: :unprocessable_entity
      return
    end

    attempt = @current_user.quiz_attempts.create!(
      book_list_id: book_list_id,
      correct_count: 0,
      total_count: total_count
    )
    render json: { attempt_id: attempt.id }
  end

  def attempt
    book_list_id = params[:book_list_id]
    correct_count = params[:correct_count].to_i
    total_count = params[:total_count].to_i
    attempt_id = params[:attempt_id].presence

    book_list = BookList.find_by(id: book_list_id)
    unless book_list
      render json: { errors: ['Book list not found'] }, status: :unprocessable_entity
      return
    end

    question_count = book_list.quiz_questions.count
    # Allow 1 or 2 points per question; support full list or 20-question quiz (20 or 40)
    expected_totals = [question_count, question_count * 2, 20, 40].uniq
    unless expected_totals.include?(total_count)
      render json: { errors: ["total_count must be one of #{expected_totals.join(', ')}"] }, status: :unprocessable_entity
      return
    end
    if correct_count > total_count
      render json: { errors: ['correct_count cannot exceed total_count'] }, status: :unprocessable_entity
      return
    end

    if attempt_id.present?
      attempt = @current_user.quiz_attempts.find_by(id: attempt_id)
      unless attempt
        render json: { errors: ['Quiz attempt not found'] }, status: :not_found
        return
      end
      attempt.update!(correct_count: correct_count, total_count: total_count)
    else
      attempt = @current_user.quiz_attempts.create!(
        book_list_id: book_list_id,
        correct_count: correct_count,
        total_count: total_count
      )
    end

    @current_user.log_activity!
    high_score = @current_user.quiz_attempts.where(book_list_id: book_list_id).maximum(:correct_count)
    render json: { high_score: high_score, attempt_id: attempt.id }
  end

  def me
    book_list_id = @current_user.team&.book_list_id
    unless book_list_id
      render json: { high_score: 0, attempts: [], latest_attempt_id: nil }
      return
    end

    attempts = @current_user.quiz_attempts.where(book_list_id: book_list_id).order(created_at: :desc)
    high_score = attempts.maximum(:correct_count) || 0
    latest_attempt_id = attempts.limit(1).pick(:id)
    render json: {
      high_score: high_score,
      attempts: attempts.map { |a| { correct_count: a.correct_count, total_count: a.total_count, created_at: a.created_at } },
      latest_attempt_id: latest_attempt_id
    }
  end

  def team_stats
    unless @current_user.team_lead?
      render json: { error: 'Forbidden: team lead access required' }, status: :forbidden
      return
    end

    book_list_id = @current_user.team&.book_list_id
    unless book_list_id
      render json: { teammates: [] }
      return
    end

    teammates = @current_user.team.teammates.includes(:quiz_attempts).to_a
    team_lead = @current_user.team.team_lead
    all_users = ([team_lead] + teammates).compact.uniq

    data = all_users.map do |u|
      user_attempts = u.quiz_attempts.where(book_list_id: book_list_id).order(created_at: :desc)
      high_score = user_attempts.maximum(:correct_count) || 0
      {
        user_id: u.id,
        username: u.username,
        attempt_count: user_attempts.count,
        high_score: high_score,
        attempts: user_attempts.map { |a| { correct_count: a.correct_count, total_count: a.total_count, created_at: a.created_at } }
      }
    end
    render json: { teammates: data }
  end

  def challenge
    attempt = @current_user.quiz_attempts.find_by(id: params[:quiz_attempt_id])
    unless attempt
      render json: { errors: ["Quiz attempt not found"] }, status: :not_found
      return
    end

    question = QuizQuestion.joins(:book_list).where(book_list: { id: attempt.book_list_id }).find_by(id: params[:quiz_question_id])
    unless question
      render json: { errors: ["Question not found for this attempt"] }, status: :not_found
      return
    end

    if attempt.quiz_challenges.exists?(quiz_question_id: question.id)
      render json: { errors: ["You have already challenged this question"] }, status: :unprocessable_entity
      return
    end

    chosen_item = BookListItem.where(book_list_id: attempt.book_list_id).find_by(id: params[:chosen_book_list_item_id])
    unless chosen_item
      render json: { errors: ["Chosen book not found on this list"] }, status: :unprocessable_entity
      return
    end

    justification = params[:justification].to_s.strip
    if justification.blank?
      render json: { errors: ["Justification is required"] }, status: :unprocessable_entity
      return
    end

    official = question.correct_book_list_item
    upheld = QuizChallengeAiService.evaluate(
      question_text: question.question_text,
      official_book: official.title,
      official_author: official.author.to_s,
      user_book: chosen_item.title,
      user_author: chosen_item.author.to_s,
      page_number: params[:page_number].to_s.strip,
      justification: justification
    )

    challenge = attempt.quiz_challenges.create!(
      user: @current_user,
      quiz_question: question,
      chosen_book_list_item: chosen_item,
      page_number: params[:page_number].to_s.strip.presence,
      justification: justification,
      upheld: upheld
    )

    if upheld
      new_count = [attempt.correct_count + 2, attempt.total_count].min
      attempt.update_column(:correct_count, new_count)
    else
      new_count = attempt.correct_count
    end

    high_score = @current_user.quiz_attempts.where(book_list_id: attempt.book_list_id).maximum(:correct_count)
    render json: { upheld: upheld, new_correct_count: new_count, high_score: high_score }
  end
end
