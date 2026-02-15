# frozen_string_literal: true

class LeaderboardController < ApplicationController
  before_action :authenticate_user!

  def index
    team = @current_user.team

    unless team.leaderboard_enabled?
      render json: { error: 'Leaderboard is disabled for this team' }, status: :forbidden
      return
    end

    book_list_id = team&.book_list_id

    # Gather all team members (team lead + teammates)
    members = team.users.order(:username).to_a

    member_ids = members.map(&:id)

    # --- Quiz stats ---
    quiz_data = if book_list_id
                  QuizAttempt
                    .where(user_id: member_ids, book_list_id: book_list_id)
                    .group(:user_id)
                    .select(
                      'user_id',
                      'MAX(correct_count) AS high_score',
                      'ROUND(AVG(correct_count)::numeric, 1) AS avg_score',
                      'COUNT(*) AS attempt_count'
                    )
                    .index_by(&:user_id)
                else
                  {}
                end

    # --- Quiz match stats ---
    completed_status = QuizMatch.statuses[:completed]
    match_rows = if book_list_id
                   QuizMatch
                     .where(team_id: team.id, status: completed_status)
                     .where('challenger_id IN (?) OR opponent_id IN (?)', member_ids, member_ids)
                     .pluck(:challenger_id, :opponent_id, :challenger_score, :opponent_score)
                 else
                   []
                 end

    match_wins  = Hash.new(0)
    match_losses = Hash.new(0)
    match_rows.each do |c_id, o_id, c_score, o_score|
      if c_score > o_score
        match_wins[c_id] += 1
        match_losses[o_id] += 1 if o_id
      elsif o_score > c_score
        match_wins[o_id] += 1 if o_id
        match_losses[c_id] += 1
      end
      # ties: no win/loss recorded
    end

    # --- Reading stats ---
    reading_data = BookAssignment
                     .where(user_id: member_ids)
                     .group(:user_id)
                     .select(
                       'user_id',
                       "SUM(CASE WHEN status = #{BookAssignment.statuses[:completed]} THEN 1 ELSE 0 END) AS books_completed",
                       'COUNT(*) AS books_assigned',
                       'ROUND(AVG(progress_percent)::numeric, 0) AS avg_progress'
                     )
                     .index_by(&:user_id)

    entries = members.map do |u|
      qd = quiz_data[u.id]
      rd = reading_data[u.id]
      {
        user_id: u.id,
        username: u.username,
        avatar_emoji: u.avatar_emoji,
        role: u.role,
        quiz_high_score: qd&.high_score.to_i,
        quiz_avg_score: qd&.avg_score.to_f,
        quiz_attempt_count: qd&.attempt_count.to_i,
        match_wins: match_wins[u.id],
        match_losses: match_losses[u.id],
        books_completed: rd&.books_completed.to_i,
        books_assigned: rd&.books_assigned.to_i,
        avg_reading_progress: rd&.avg_progress.to_i
      }
    end

    render json: { entries: entries }
  end
end
