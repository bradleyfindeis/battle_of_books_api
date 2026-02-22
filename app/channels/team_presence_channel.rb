# frozen_string_literal: true

class TeamPresenceChannel < ApplicationCable::Channel
  def subscribed
    @team_id = current_user.team_id

    # #region agent log
    Rails.logger.info("[DEBUG H5] TeamPresenceChannel#subscribed user_id=#{current_user.id} team_id=#{@team_id} pid=#{Process.pid}")
    # #endregion

    stream_for "team_#{@team_id}"

    PresenceTracker.add(@team_id, current_user.id)
  end

  def unsubscribed
    # #region agent log
    Rails.logger.info("[DEBUG H5] TeamPresenceChannel#unsubscribed user_id=#{current_user&.id} team_id=#{@team_id} pid=#{Process.pid}")
    # #endregion

    return unless @team_id

    PresenceTracker.remove(@team_id, current_user.id)
  end
end
