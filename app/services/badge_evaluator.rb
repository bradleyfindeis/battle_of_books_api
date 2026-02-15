# frozen_string_literal: true

# Evaluates which badges a user has earned, calculated on the fly from existing data.
# Each badge is { key:, name:, description:, emoji:, earned: bool, progress: string|nil }
class BadgeEvaluator
  def initialize(user)
    @user = user
    @team = user.team
  end

  def evaluate
    [
      bookworm_badge,
      quiz_master_badge,
      quiz_regular_badge,
      first_quiz_badge,
      challenger_badge,
      match_winner_badge,
      undefeated_badge,
      streak_badge,
      dedicated_badge,
      all_rounder_badge
    ]
  end

  private

  # --- Reading badges ---

  def bookworm_badge
    assigned = @user.book_assignments.count
    completed = @user.book_assignments.where(status: :completed).count
    earned = assigned > 0 && completed == assigned
    {
      key: 'bookworm',
      name: 'Bookworm',
      description: 'Complete all assigned books',
      emoji: '📖',
      earned: earned,
      progress: assigned > 0 ? "#{completed}/#{assigned} books" : nil
    }
  end

  # --- Quiz badges ---

  def quiz_master_badge
    book_list_id = @team&.book_list_id
    return badge_stub('quiz_master', 'Quiz Master', 'Score 100% on a quiz', '🏆') unless book_list_id

    best = @user.quiz_attempts.where(book_list_id: book_list_id).maximum(:correct_count) || 0
    max_possible = @user.quiz_attempts.where(book_list_id: book_list_id).maximum(:total_count) || 0
    earned = max_possible > 0 && best == max_possible
    {
      key: 'quiz_master',
      name: 'Quiz Master',
      description: 'Score 100% on a quiz',
      emoji: '🏆',
      earned: earned,
      progress: max_possible > 0 ? "Best: #{best}/#{max_possible}" : nil
    }
  end

  def quiz_regular_badge
    book_list_id = @team&.book_list_id
    return badge_stub('quiz_regular', 'Quiz Regular', 'Complete 10 quizzes', '📝') unless book_list_id

    count = @user.quiz_attempts.where(book_list_id: book_list_id).count
    {
      key: 'quiz_regular',
      name: 'Quiz Regular',
      description: 'Complete 10 quizzes',
      emoji: '📝',
      earned: count >= 10,
      progress: "#{[count, 10].min}/10 quizzes"
    }
  end

  def first_quiz_badge
    book_list_id = @team&.book_list_id
    return badge_stub('first_quiz', 'First Steps', 'Complete your first quiz', '🌟') unless book_list_id

    count = @user.quiz_attempts.where(book_list_id: book_list_id).count
    {
      key: 'first_quiz',
      name: 'First Steps',
      description: 'Complete your first quiz',
      emoji: '🌟',
      earned: count >= 1,
      progress: nil
    }
  end

  # --- Match badges ---

  def challenger_badge
    upheld = @user.quiz_challenges.where(upheld: true).count
    {
      key: 'challenger',
      name: 'Sharp Eye',
      description: 'Successfully challenge a quiz answer',
      emoji: '🔍',
      earned: upheld >= 1,
      progress: upheld > 0 ? "#{upheld} upheld" : nil
    }
  end

  def match_winner_badge
    wins = count_match_wins
    {
      key: 'match_winner',
      name: 'Match Winner',
      description: 'Win 5 head-to-head matches',
      emoji: '⚔️',
      earned: wins >= 5,
      progress: "#{[wins, 5].min}/5 wins"
    }
  end

  def undefeated_badge
    # Check for 5 consecutive wins (most recent matches)
    streak = longest_win_streak
    {
      key: 'undefeated',
      name: 'Undefeated',
      description: 'Win 5 matches in a row',
      emoji: '🔥',
      earned: streak >= 5,
      progress: streak > 0 ? "Best streak: #{streak}" : nil
    }
  end

  # --- Activity badges ---

  def streak_badge
    streak = @user.current_streak
    {
      key: 'streak_7',
      name: 'On Fire',
      description: 'Reach a 7-day activity streak',
      emoji: '🔥',
      earned: streak >= 7 || max_streak >= 7,
      progress: "Current: #{streak} days"
    }
  end

  def dedicated_badge
    total_days = @user.activity_days.count
    {
      key: 'dedicated',
      name: 'Dedicated',
      description: 'Be active for 30 days total',
      emoji: '💪',
      earned: total_days >= 30,
      progress: "#{[total_days, 30].min}/30 days"
    }
  end

  def all_rounder_badge
    book_list_id = @team&.book_list_id
    has_quiz = book_list_id && @user.quiz_attempts.where(book_list_id: book_list_id).exists?
    has_match = completed_matches.any?
    has_reading = @user.book_assignments.exists?
    earned = has_quiz && has_match && has_reading
    {
      key: 'all_rounder',
      name: 'Team Player',
      description: 'Complete at least one quiz, match, and book assignment',
      emoji: '⭐',
      earned: earned,
      progress: nil
    }
  end

  # --- Helpers ---

  def badge_stub(key, name, description, emoji)
    { key: key, name: name, description: description, emoji: emoji, earned: false, progress: nil }
  end

  def completed_matches
    @completed_matches ||= QuizMatch
      .where(status: QuizMatch.statuses[:completed])
      .where('challenger_id = ? OR opponent_id = ?', @user.id, @user.id)
      .order(created_at: :desc)
      .pluck(:challenger_id, :opponent_id, :challenger_score, :opponent_score)
  end

  def count_match_wins
    completed_matches.count do |c_id, _o_id, c_score, o_score|
      (@user.id == c_id && c_score > o_score) || (@user.id != c_id && o_score > c_score)
    end
  end

  def longest_win_streak
    streak = 0
    best = 0
    completed_matches.each do |c_id, _o_id, c_score, o_score|
      won = (@user.id == c_id && c_score > o_score) || (@user.id != c_id && o_score > c_score)
      if won
        streak += 1
        best = streak if streak > best
      else
        streak = 0
      end
    end
    best
  end

  def max_streak
    # Check if user ever had a 7-day streak by scanning all activity days
    dates = @user.activity_days.order(activity_date: :desc).pluck(:activity_date)
    return 0 if dates.empty?

    best = 1
    current = 1
    dates.each_cons(2) do |a, b|
      if a - b == 1
        current += 1
        best = current if current > best
      else
        current = 1
      end
    end
    best
  end
end
