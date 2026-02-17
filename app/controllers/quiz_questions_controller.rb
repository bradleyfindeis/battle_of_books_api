# frozen_string_literal: true

class QuizQuestionsController < ApplicationController
  QUIZ_QUESTION_LIMIT = 20
  MY_BOOKS_ASSIGNED_PCT = 0.6

  DIFFICULTY_WEIGHTS = {
    'easy'   => { easy: 0.70, medium: 0.25, hard: 0.05 },
    'medium' => { easy: 0.15, medium: 0.70, hard: 0.15 },
    'hard'   => { easy: 0.05, medium: 0.25, hard: 0.70 }
  }.freeze

  before_action :authenticate_user!
  before_action :set_book_list

  def index
    mode = (params[:mode].presence || "all").to_s
    mode = "all" unless %w[all my_books].include?(mode)

    difficulty = params[:difficulty].presence
    difficulty = nil unless %w[easy medium hard].include?(difficulty)

    questions = fetch_questions_for_mode(mode, difficulty)
    choices = @book_list.book_list_items.order(:position).map { |item| BookListItemSerializer.new(item).as_json }
    data = questions.map do |q|
      {
        id: q.id,
        question_text: q.question_text,
        position: q.position,
        difficulty: q.difficulty,
        correct_book_list_item_id: q.correct_book_list_item_id,
        choices: choices
      }
    end
    render json: data
  end

  private

  def set_book_list
    @book_list = BookList.find(params[:book_list_id])
  end

  def fetch_questions_for_mode(mode, difficulty)
    all_questions = @book_list.quiz_questions.includes(:correct_book_list_item).to_a

    all_questions = apply_difficulty_weights(all_questions, difficulty, QUIZ_QUESTION_LIMIT) if difficulty

    return sample_and_order(all_questions, QUIZ_QUESTION_LIMIT) if mode == "all"

    assigned_ids = assigned_book_list_item_ids(@current_user, @book_list)
    return sample_and_order(all_questions, QUIZ_QUESTION_LIMIT) if assigned_ids.empty?

    from_assigned = all_questions.select { |q| assigned_ids.include?(q.correct_book_list_item_id) }
    from_others = all_questions.reject { |q| assigned_ids.include?(q.correct_book_list_item_id) }

    n_assigned = (QUIZ_QUESTION_LIMIT * MY_BOOKS_ASSIGNED_PCT).round
    n_others = QUIZ_QUESTION_LIMIT - n_assigned

    sampled_assigned = from_assigned.sample([n_assigned, from_assigned.size].min)
    sampled_others = from_others.sample([n_others, from_others.size].min)
    combined = sampled_assigned + sampled_others
    needed = QUIZ_QUESTION_LIMIT - combined.size
    if needed.positive?
      remaining = (from_assigned - sampled_assigned) + (from_others - sampled_others)
      combined += remaining.sample([needed, remaining.size].min)
    end
    combined.shuffle.take(QUIZ_QUESTION_LIMIT)
  end

  def apply_difficulty_weights(questions, difficulty, limit)
    weights = DIFFICULTY_WEIGHTS[difficulty]
    return questions unless weights

    grouped = questions.group_by { |q| q.difficulty.to_sym }

    targets = weights.transform_values { |pct| (limit * pct).round }
    total_target = targets.values.sum
    if total_target != limit
      max_key = targets.max_by { |_, v| v }.first
      targets[max_key] += (limit - total_target)
    end

    selected = []
    overflow = []

    targets.each do |diff_level, target_count|
      pool = grouped[diff_level] || []
      taken = pool.sample([target_count, pool.size].min)
      selected.concat(taken)
      overflow.concat(pool - taken) if taken.size < target_count
    end

    needed = limit - selected.size
    if needed.positive?
      all_remaining = questions - selected
      selected.concat(all_remaining.sample([needed, all_remaining.size].min))
    end

    selected
  end

  def sample_and_order(questions, limit)
    questions.sample([limit, questions.size].min).sort_by(&:position)
  end

  def assigned_book_list_item_ids(user, book_list)
    return [] if user.blank? || book_list.blank?

    assigned_pairs = user.assigned_books.map do |b|
      [b.title.to_s.strip.downcase, (b.author || "").to_s.strip.downcase]
    end.uniq

    book_list.book_list_items.select do |item|
      pair = [item.title.to_s.strip.downcase, (item.author || "").to_s.strip.downcase]
      assigned_pairs.include?(pair)
    end.map(&:id)
  end
end
