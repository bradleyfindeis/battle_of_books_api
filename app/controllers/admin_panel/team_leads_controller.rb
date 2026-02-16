# frozen_string_literal: true

module AdminPanel
  class TeamLeadsController < BaseController
    # GET /admin/team_leads
    # Returns all team leads, with managed_team_count per email.
    # Excludes leads who already manage 2 teams.
    def index
      leads = User.where(role: :team_lead).includes(:team)

      email_counts = leads.group(:email).count

      result = leads
        .select { |u| (email_counts[u.email] || 0) < 6 }
        .map do |u|
          {
            id: u.id,
            username: u.username,
            email: u.email,
            team_id: u.team_id,
            team_name: u.team&.name,
            managed_team_count: email_counts[u.email] || 1
          }
        end

      render json: result
    end
  end
end
