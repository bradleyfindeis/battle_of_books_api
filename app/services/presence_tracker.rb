# frozen_string_literal: true

require "set"

class PresenceTracker
  # team_id -> { user_id -> connection_count }
  CONNECTIONS = Concurrent::Map.new
  MUTEX = Mutex.new

  # Register a connection for a user on a team.
  # Returns the current set of online user IDs for the team.
  def self.add(team_id, user_id)
    MUTEX.synchronize do
      counts = CONNECTIONS.fetch_or_store(team_id) { Concurrent::Map.new }
      current = counts.fetch_or_store(user_id) { 0 }
      counts[user_id] = current + 1
    end
    broadcast(team_id)
  end

  # Remove a connection for a user on a team.
  # Only removes the user from the online set when all connections are gone (handles multiple tabs).
  def self.remove(team_id, user_id)
    MUTEX.synchronize do
      counts = CONNECTIONS[team_id]
      if counts
        current = counts[user_id].to_i
        if current <= 1
          counts.delete(user_id)
        else
          counts[user_id] = current - 1
        end
      end
    end
    broadcast(team_id)
  end

  # Returns an array of user IDs currently online for the given team.
  def self.online_user_ids(team_id)
    MUTEX.synchronize do
      counts = CONNECTIONS[team_id]
      counts ? counts.keys : []
    end
  end

  # Broadcast the current online user list to all subscribers of the team presence stream.
  def self.broadcast(team_id)
    TeamPresenceChannel.broadcast_to(
      "team_#{team_id}",
      { type: "presence_update", online_user_ids: online_user_ids(team_id) }
    )
  end
end
