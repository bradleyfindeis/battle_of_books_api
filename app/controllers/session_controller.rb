class SessionController < ApplicationController
  # GET /auth/session
  # Returns current session state for both user and admin sessions.
  # Automatically refreshes expired access tokens using refresh tokens.
  def check
    result = {}

    # ── User session ──
    user = current_user_from_cookie || current_user_from_header || refresh_user_session!
    if user
      team = user.team
      team.resolve_book_list!
      result[:user] = UserSerializer.new(user).as_json
      result[:team] = TeamSerializer.new(team.reload, include_details: user.team_lead?).as_json
      result[:pin_reset_required] = user.pin_reset_required
      result[:token] = AuthService.encode(user_id: user.id)
      if user.team_lead? && user.email.present?
        result[:managed_teams] = User.where(role: :team_lead, email: user.email)
                                     .includes(:team)
                                     .map { |u| { id: u.team.id, name: u.team.name } }
      end
    end

    # ── Admin session ──
    admin = current_admin_from_cookie || current_admin_from_header || refresh_admin_session!
    if admin
      result[:admin] = { id: admin.id, email: admin.email }
      result[:admin_token] = AdminAuthService.encode(admin_id: admin.id)
    end

    render json: result
  end

  # POST /auth/refresh
  # Lightweight token refresh for the Axios interceptor.
  # Attempts to refresh any expired access tokens using refresh cookies.
  def refresh
    user_refreshed = !current_user_from_cookie && !!refresh_user_session!
    admin_refreshed = !current_admin_from_cookie && !!refresh_admin_session!

    if user_refreshed || admin_refreshed
      head :no_content
    else
      render json: { error: 'Unable to refresh session' }, status: :unauthorized
    end
  end

  # DELETE /auth/logout
  # Revokes all refresh tokens and clears all auth cookies.
  def logout
    revoke_user_refresh_token
    revoke_admin_refresh_token
    clear_user_cookies
    clear_admin_cookies
    render json: { message: 'Logged out' }
  end

  # DELETE /auth/user_session
  # Clears only the user session cookies (used to exit demo mode).
  def clear_user_session
    revoke_user_refresh_token
    clear_user_cookies
    render json: { message: 'User session cleared' }
  end

  private

  def revoke_user_refresh_token
    raw = cookies[:user_refresh_token]
    return unless raw

    rt = RefreshToken.find_by_raw_token(raw)
    rt&.revoke!
  end

  def revoke_admin_refresh_token
    raw = cookies[:admin_refresh_token]
    return unless raw

    rt = RefreshToken.find_by_raw_token(raw)
    rt&.revoke!
  end
end
