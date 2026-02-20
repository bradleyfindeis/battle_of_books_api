class ApplicationController < ActionController::API
  include ActionController::Cookies
  include CookieAuth

  private

  def authenticate_user!
    @current_user = current_user_from_cookie || current_user_from_header || refresh_user_session!
    render_unauthorized unless @current_user
  end

  def authenticate_admin!
    # #region agent log
    from_cookie = current_admin_from_cookie
    from_header = from_cookie ? nil : current_admin_from_header
    from_refresh = (from_cookie || from_header) ? nil : refresh_admin_session!
    @current_admin = from_cookie || from_header || from_refresh
    File.open(Rails.root.join('.cursor', 'debug.log'), 'a') do |f|
      f.puts({ location: 'application_controller.rb:authenticate_admin!', message: 'auth_check',
               data: { from_cookie: !!from_cookie, from_header: !!from_header, from_refresh: !!from_refresh, authenticated: !!@current_admin, has_bearer: request.headers['Authorization']&.start_with?('Bearer ').present? },
               timestamp: Time.now.to_i * 1000, hypothesisId: 'H1' }.to_json)
    end
    # #endregion
    render_unauthorized unless @current_admin
  end

  def require_team_lead!
    render json: { error: 'Forbidden: team lead access required' }, status: :forbidden unless @current_user&.team_lead?
  end

  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def bearer_token
    request.headers['Authorization']&.match(/\ABearer (.+)\z/)&.captures&.first
  end

  def current_user_from_header
    token = bearer_token
    return nil unless token
    decoded = AuthService.decode(token)
    User.find_by(id: decoded[:user_id]) if decoded&.key?(:user_id)
  end

  def current_admin_from_header
    token = bearer_token
    return nil unless token
    decoded = AdminAuthService.decode(token)
    Admin.find_by(id: decoded[:admin_id]) if decoded&.key?(:admin_id)
  end
end
