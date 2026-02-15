class UsersController < ApplicationController
  before_action :authenticate_user!

  def me
    team = @current_user.team
    team.resolve_book_list! # backfill book_list_id from team's books if missing
    render json: { user: UserSerializer.new(@current_user).as_json, team: TeamSerializer.new(team.reload, include_details: @current_user.team_lead?).as_json }
  end

  def my_streak
    streak = @current_user.current_streak
    active_today = @current_user.activity_days.exists?(activity_date: Date.current)
    render json: { streak: streak, active_today: active_today }
  end

  def my_badges
    badges = BadgeEvaluator.new(@current_user).evaluate
    render json: { badges: badges }
  end

  def update_avatar
    emoji = params[:avatar_emoji].to_s.strip
    if emoji.blank?
      @current_user.update!(avatar_emoji: nil)
    else
      @current_user.update!(avatar_emoji: emoji)
    end
    render json: UserSerializer.new(@current_user).as_json
  end

  def my_progress
    book_list_id = @current_user.team&.book_list_id

    # Lifetime quiz stats
    quiz_attempts = @current_user.quiz_attempts
    quiz_attempts = quiz_attempts.where(book_list_id: book_list_id) if book_list_id
    total_quizzes = quiz_attempts.count
    quiz_high_score = quiz_attempts.maximum(:correct_count) || 0
    quiz_max_possible = quiz_attempts.maximum(:total_count) || 0
    quiz_avg_pct = if total_quizzes > 0
                     scores = quiz_attempts.pluck(:correct_count, :total_count)
                     (scores.sum { |c, t| t > 0 ? (c.to_f / t * 100) : 0 } / scores.size).round
                   else
                     0
                   end

    # Last 20 quiz attempts (for trend chart)
    recent_quizzes = quiz_attempts.order(created_at: :desc).limit(20).map do |a|
      { correct_count: a.correct_count, total_count: a.total_count, created_at: a.created_at }
    end.reverse # oldest first for chart

    # Lifetime match stats
    all_matches = QuizMatch.status_completed
                           .where('challenger_id = :uid OR opponent_id = :uid', uid: @current_user.id)
    total_matches = all_matches.count
    match_data = all_matches.pluck(:challenger_id, :opponent_id, :challenger_score, :opponent_score)
    match_wins = match_data.count { |c_id, _, c_s, o_s| (@current_user.id == c_id && c_s > o_s) || (@current_user.id != c_id && o_s > c_s) }
    match_losses = match_data.count { |c_id, _, c_s, o_s| (@current_user.id == c_id && c_s < o_s) || (@current_user.id != c_id && o_s < c_s) }
    match_ties = total_matches - match_wins - match_losses

    # Reading progress
    assignments = @current_user.book_assignments.includes(:book).map do |a|
      {
        book_title: a.book&.title || 'Unknown',
        book_author: a.book&.author,
        status: a.status,
        progress_percent: a.progress_percent || 0
      }
    end
    books_completed = assignments.count { |a| a[:status] == 'completed' }
    books_total = assignments.size

    # Activity days (last 30 days for calendar)
    thirty_days_ago = 29.days.ago.to_date
    active_dates = @current_user.activity_days
                                .where(activity_date: thirty_days_ago..Date.current)
                                .pluck(:activity_date)
                                .map(&:iso8601)

    total_active_days = @current_user.activity_days.count
    current_streak = @current_user.current_streak

    render json: {
      quiz: {
        total_attempts: total_quizzes,
        high_score: quiz_high_score,
        max_possible: quiz_max_possible,
        avg_percent: quiz_avg_pct,
        recent: recent_quizzes
      },
      matches: {
        total: total_matches,
        wins: match_wins,
        losses: match_losses,
        ties: match_ties
      },
      reading: {
        books_completed: books_completed,
        books_total: books_total,
        assignments: assignments
      },
      activity: {
        total_active_days: total_active_days,
        current_streak: current_streak,
        recent_dates: active_dates
      }
    }
  end

  def my_weekly_summary
    week_start = Date.current.beginning_of_week(:monday)
    week_range = week_start.beginning_of_day..Time.current

    # Quiz attempts this week
    quiz_attempts_this_week = @current_user.quiz_attempts.where(created_at: week_range)
    quizzes_completed = quiz_attempts_this_week.count
    quiz_avg_score = if quizzes_completed > 0
                       scores = quiz_attempts_this_week.pluck(:correct_count, :total_count)
                       avg_pct = scores.sum { |c, t| t > 0 ? (c.to_f / t * 100) : 0 } / scores.size
                       avg_pct.round
                     else
                       0
                     end

    # Head-to-head matches this week
    matches_this_week = QuizMatch.status_completed
                                 .where(created_at: week_range)
                                 .where('challenger_id = :uid OR opponent_id = :uid', uid: @current_user.id)
    matches_played = matches_this_week.count
    matches_won = matches_this_week.count { |m|
      if m.challenger_id == @current_user.id
        m.challenger_score > m.opponent_score
      else
        m.opponent_score > m.challenger_score
      end
    }

    # Books finished this week (status changed to completed)
    books_finished = @current_user.book_assignments
                                  .where(status: :completed)
                                  .where(updated_at: week_range)
                                  .count

    # Days active this week
    days_active = @current_user.activity_days
                               .where(activity_date: week_start..Date.current)
                               .count

    render json: {
      week_start: week_start.iso8601,
      quizzes_completed: quizzes_completed,
      quiz_avg_score: quiz_avg_score,
      matches_played: matches_played,
      matches_won: matches_won,
      books_finished: books_finished,
      days_active: days_active
    }
  end

  def team_reading_progress
    team = @current_user.team
    teammate_ids = team.users.pluck(:id)

    assignments = BookAssignment.where(user_id: teammate_ids).includes(:book, :user)

    total_assignments = assignments.count
    completed_count = assignments.where(status: :completed).count
    in_progress_count = assignments.where(status: :in_progress).count
    avg_progress = if total_assignments > 0
                     assignments.map { |a| a.status == 'completed' ? 100 : (a.progress_percent || 0) }.sum / total_assignments
                   else
                     0
                   end

    # Per-teammate breakdown
    teammates = team.users.where(role: :teammate).order(:username).map do |u|
      user_assignments = assignments.select { |a| a.user_id == u.id }
      total = user_assignments.size
      done = user_assignments.count { |a| a.status == 'completed' }
      pct = total > 0 ? (user_assignments.sum { |a| a.status == 'completed' ? 100 : (a.progress_percent || 0) } / total) : 0
      {
        user_id: u.id,
        username: u.username,
        avatar_emoji: u.avatar_emoji,
        books_assigned: total,
        books_completed: done,
        avg_progress: pct
      }
    end

    # Recently completed (last 5)
    recently_completed = assignments
      .select { |a| a.status == 'completed' }
      .sort_by { |a| a.updated_at || a.created_at }
      .last(5)
      .reverse
      .map { |a| { username: a.user&.username, book_title: a.book&.title, completed_at: a.updated_at } }

    render json: {
      total_assignments: total_assignments,
      completed_count: completed_count,
      in_progress_count: in_progress_count,
      avg_progress: avg_progress,
      teammates: teammates,
      recently_completed: recently_completed
    }
  end
end
