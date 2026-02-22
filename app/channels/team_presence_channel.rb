# frozen_string_literal: true

class TeamPresenceChannel < ApplicationCable::Channel
  def subscribed
    @team_id = current_user.team_id

    stream_for "team_#{@team_id}"

    PresenceTracker.add(@team_id, current_user.id)
  end

  def unsubscribed
    return unless @team_id

    PresenceTracker.remove(@team_id, current_user.id)
  end
end
