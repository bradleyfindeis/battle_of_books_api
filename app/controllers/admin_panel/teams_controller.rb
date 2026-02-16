module AdminPanel
  class TeamsController < BaseController
    before_action :set_team, only: [:update, :destroy, :assign_existing_lead]

    def index
      teams = Team.includes(:team_lead, :teammates, :invite_code).order(created_at: :desc)
      render json: teams.map { |t| TeamSerializer.new(t, admin: true).as_json }
    end

    def show
      @team = Team.includes(:users, :books).find(params[:id])
      render json: TeamSerializer.new(@team, admin: true, include_details: true).as_json
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Team not found' }, status: :not_found
    end

    def create
      team = Team.new(team_params)
      if team.save
        render json: TeamSerializer.new(team, admin: true).as_json, status: :created
      else
        render json: { errors: team.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if params.key?(:team_lead_id)
        lead_id = params[:team_lead_id]
        if lead_id.nil? || lead_id.to_s == ''
          @team.team_lead&.update!(role: :teammate)
        else
          user = @team.users.find_by(id: lead_id)
          if user
            @team.team_lead&.update!(role: :teammate)
            user.update!(role: :team_lead)
          end
        end
      end
      if @team.update(team_params)
        render json: TeamSerializer.new(@team.reload, admin: true).as_json
      else
        render json: { errors: @team.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Team not found' }, status: :not_found
    end

    def destroy
      @team.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Team not found' }, status: :not_found
    end

    # POST /admin/teams/:id/assign_existing_lead
    def assign_existing_lead
      source_user = User.where(role: :team_lead).find_by(id: params[:user_id])
      unless source_user
        return render json: { error: 'Team lead not found' }, status: :not_found
      end

      managed_count = User.where(role: :team_lead, email: source_user.email).count
      if managed_count >= 6
        return render json: { error: 'This team lead already manages 6 teams' }, status: :unprocessable_entity
      end

      if @team.users.exists?(role: :team_lead, email: source_user.email)
        return render json: { error: 'This team lead is already on this team' }, status: :unprocessable_entity
      end

      ActiveRecord::Base.transaction do
        @team.team_lead&.update!(role: :teammate)

        @team.users.create!(
          username: source_user.username,
          email: source_user.email,
          pin_code_digest: source_user.pin_code_digest,
          role: :team_lead,
          pin_reset_required: false
        )
      end

      render json: TeamSerializer.new(@team.reload, admin: true, include_details: true).as_json
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def set_team
      @team = Team.find(params[:id])
    end

    def team_params
      params.permit(:name, :invite_code_id)
    end
  end
end
