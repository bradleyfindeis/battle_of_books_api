# frozen_string_literal: true

class QuizMatchQuestionBuilder
  COUNT = 20
  ASSIGNED_PCT = 0.4 # ~40% from challenger's books, ~40% from opponent's, ~20% shared/alternating

  DIFFICULTY_WEIGHTS = {
    'easy'   => { easy: 0.70, medium: 0.25, hard: 0.05 },
    'medium' => { easy: 0.15, medium: 0.70, hard: 0.15 },
    'hard'   => { easy: 0.05, medium: 0.25, hard: 0.70 }
  }.freeze

  def self.build(challenger:, opponent:, book_list:, difficulty: nil)
    new(challenger: challenger, opponent: opponent, book_list: book_list, difficulty: difficulty).build
  end

  def initialize(challenger:, opponent:, book_list:, difficulty: nil)
    @challenger = challenger
    @opponent = opponent
    @book_list = book_list
    @difficulty = difficulty
  end

  def build
    all_questions = @book_list.quiz_questions.includes(:correct_book_list_item).to_a

    all_questions = apply_difficulty_weights(all_questions) if @difficulty.present?

    return [] if all_questions.size < COUNT

    challenger_ids = assigned_book_list_item_ids(@challenger)
    opponent_ids = assigned_book_list_item_ids(@opponent)

    from_challenger = all_questions.select { |q| challenger_ids.include?(q.correct_book_list_item_id) }
    from_opponent = all_questions.select { |q| opponent_ids.include?(q.correct_book_list_item_id) }
    from_neither = all_questions.reject { |q| challenger_ids.include?(q.correct_book_list_item_id) || opponent_ids.include?(q.correct_book_list_item_id) }

    n_per = (COUNT * ASSIGNED_PCT).round
    n_challenger = [n_per, from_challenger.size].min
    n_opponent = [n_per, from_opponent.size].min
    n_rest = COUNT - n_challenger - n_opponent
    n_rest = [n_rest, from_neither.size].min if n_rest > from_neither.size

    sampled_challenger = from_challenger.sample(n_challenger)
    sampled_opponent = from_opponent.sample(n_opponent)
    needed_from_neither = COUNT - sampled_challenger.size - sampled_opponent.size
    sampled_neither = from_neither.sample([needed_from_neither, from_neither.size].min)

    combined = sampled_challenger + sampled_opponent + sampled_neither
    needed = COUNT - combined.size
    if needed.positive?
      remaining = (from_challenger - sampled_challenger) + (from_opponent - sampled_opponent) + (from_neither - sampled_neither)
      combined += remaining.sample([needed, remaining.size].min)
    end

    questions = combined.shuffle.take(COUNT)

    questions.map.with_index do |q, index|
      first_responder_id = index.even? ? @challenger.id : @opponent.id
      {
        'quiz_question_id' => q.id,
        'first_responder_id' => first_responder_id
      }
    end
  end

  private

  def apply_difficulty_weights(questions)
    weights = DIFFICULTY_WEIGHTS[@difficulty]
    return questions unless weights

    grouped = questions.group_by { |q| q.difficulty.to_sym }

    targets = weights.transform_values { |pct| (COUNT * pct).round }
    total_target = targets.values.sum
    if total_target != COUNT
      max_key = targets.max_by { |_, v| v }.first
      targets[max_key] += (COUNT - total_target)
    end

    selected = []

    targets.each do |diff_level, target_count|
      pool = grouped[diff_level] || []
      selected.concat(pool.sample([target_count, pool.size].min))
    end

    needed = COUNT - selected.size
    if needed.positive?
      all_remaining = questions - selected
      selected.concat(all_remaining.sample([needed, all_remaining.size].min))
    end

    selected
  end

  def assigned_book_list_item_ids(user)
    return [] if user.blank? || @book_list.blank?

    assigned_pairs = user.assigned_books.map do |b|
      [b.title.to_s.strip.downcase, (b.author || '').to_s.strip.downcase]
    end.uniq

    @book_list.book_list_items.select do |item|
      pair = [item.title.to_s.strip.downcase, (item.author || '').to_s.strip.downcase]
      assigned_pairs.include?(pair)
    end.map(&:id)
  end
end
