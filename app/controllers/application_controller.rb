class ApplicationController < ActionController::API
  include ActionController::Cookies
  include CookieAuth

  private

  def authenticate_user!
    # Try cookie first, then fall back to Authorization header
    @current_user = current_user_from_cookie
    unless @current_user
      header = request.headers['Authorization']
      token = header&.split(' ')&.last
      decoded = AuthService.decode(token)
      @current_user = User.find_by(id: decoded[:user_id]) if decoded
    end
    render_unauthorized unless @current_user
  end

  def authenticate_admin!
    @current_admin = current_admin_from_cookie
    unless @current_admin
      header = request.headers['Authorization']
      token = header&.split(' ')&.last
      decoded = AdminAuthService.decode(token)
      @current_admin = Admin.find_by(id: decoded[:admin_id]) if decoded
    end
    render_unauthorized unless @current_admin
  end

  def require_team_lead!
    render json: { error: 'Forbidden: team lead access required' }, status: :forbidden unless @current_user&.team_lead?
  end

  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
