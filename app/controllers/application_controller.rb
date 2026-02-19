class ApplicationController < ActionController::API
  include ActionController::Cookies
  include CookieAuth

  private

  def authenticate_user!
    @current_user = current_user_from_cookie || refresh_user_session!
    render_unauthorized unless @current_user
  end

  def authenticate_admin!
    @current_admin = current_admin_from_cookie || refresh_admin_session!
    render_unauthorized unless @current_admin
  end

  def require_team_lead!
    render json: { error: 'Forbidden: team lead access required' }, status: :forbidden unless @current_user&.team_lead?
  end

  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
