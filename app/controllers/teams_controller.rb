# frozen_string_literal: true

class TeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_team_lead!

  def update_my_team
    team = @current_user.team
    book_list_id = params[:book_list_id]
    if book_list_id.blank?
      render json: { errors: ['book_list_id is required'] }, status: :unprocessable_entity
      return
    end
    unless BookList.exists?(book_list_id)
      render json: { errors: ['Book list not found'] }, status: :unprocessable_entity
      return
    end
    if team.update(book_list_id: book_list_id)
      render json: TeamSerializer.new(team, include_details: true).as_json
    else
      render json: { errors: team.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
