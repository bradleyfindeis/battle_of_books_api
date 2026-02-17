# frozen_string_literal: true

class TeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_team_lead!

  # POST /create_team
  def create_team
    managed_count = User.where(role: :team_lead, email: @current_user.email).count
    if managed_count >= 6
      return render json: { error: 'You already manage 6 teams' }, status: :unprocessable_entity
    end

    invite_code = InviteCode.find_by(code: params[:invite_code]&.upcase)
    unless invite_code&.available?
      return render json: { error: 'Invalid or expired invite code' }, status: :unprocessable_entity
    end

    team_name = params[:team_name].to_s.strip
    if team_name.blank?
      return render json: { error: 'Team name is required' }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      team = Team.create!(name: team_name, invite_code: invite_code)
      new_user = User.new(
        username: @current_user.username,
        email: @current_user.email,
        pin_code_digest: @current_user.pin_code_digest,
        role: :team_lead,
        team: team,
        pin_reset_required: false
      )
      new_user.save!
      invite_code.use!

      set_user_auth_cookies(new_user)
      token = AuthService.encode(user_id: new_user.id)
      managed_teams = User.where(role: :team_lead, email: new_user.email)
                          .includes(:team)
                          .map { |u| { id: u.team.id, name: u.team.name } }

      render json: {
        token: token,
        user: UserSerializer.new(new_user).as_json,
        team: TeamSerializer.new(team).as_json,
        pin_reset_required: false,
        managed_teams: managed_teams
      }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def update_my_team
    team = @current_user.team
    attrs = {}

    if params.key?(:book_list_id)
      book_list_id = params[:book_list_id]
      if book_list_id.blank?
        render json: { errors: ['book_list_id is required'] }, status: :unprocessable_entity
        return
      end
      unless BookList.exists?(book_list_id)
        render json: { errors: ['Book list not found'] }, status: :unprocessable_entity
        return
      end
      attrs[:book_list_id] = book_list_id
    end

    if params.key?(:leaderboard_enabled)
      attrs[:leaderboard_enabled] = ActiveModel::Type::Boolean.new.cast(params[:leaderboard_enabled])
    end

    if attrs.empty?
      render json: { errors: ['No valid parameters provided'] }, status: :unprocessable_entity
      return
    end

    if team.update(attrs)
      render json: TeamSerializer.new(team, include_details: true).as_json
    else
      render json: { errors: team.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
