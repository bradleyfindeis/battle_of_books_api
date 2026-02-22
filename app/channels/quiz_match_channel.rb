# frozen_string_literal: true

class QuizMatchChannel < ApplicationCable::Channel
  def subscribed
    @match = QuizMatch.find_by(id: params[:match_id])
    if @match && @match.participant?(current_user)
      Rails.logger.info("[QuizMatch] channel subscribed user_id=#{current_user.id} match_id=#{@match.id}")
      stream_for @match
    else
      Rails.logger.info("[QuizMatch] channel REJECTED user_id=#{current_user&.id} match_id=#{params[:match_id]} match_found=#{@match.present?} participant=#{@match&.participant?(current_user)}")
      reject
    end
  end

  def unsubscribed
    cancel_match_if_in_progress
    stop_all_streams
  end

  private

  def cancel_match_if_in_progress
    return unless @match

    @match.reload
    return unless @match.status_in_progress?

    @match.update!(status: :cancelled, phase: :completed, phase_entered_at: nil)
    payload = QuizMatchPayloadBuilder.build(@match).stringify_keys
    QuizMatchChannel.broadcast_to(@match, payload)
  end
end
