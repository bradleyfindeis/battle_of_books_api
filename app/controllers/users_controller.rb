class UsersController < ApplicationController
  before_action :authenticate_user!

  def me
    team = @current_user.team
    team.resolve_book_list! # backfill book_list_id from team's books if missing
    render json: { user: UserSerializer.new(@current_user).as_json, team: TeamSerializer.new(team.reload, include_details: @current_user.team_lead?).as_json }
  end
end
