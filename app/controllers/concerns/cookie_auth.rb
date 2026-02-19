module CookieAuth
  extend ActiveSupport::Concern

  private

  def cookie_options(max_age: nil)
    opts = {
      httponly: true,
      secure: true,
      same_site: :lax,
      path: '/'
    }
    opts[:max_age] = max_age if max_age
    opts
  end

  def set_user_auth_cookies(user)
    access_token = AuthService.encode(user_id: user.id)
    refresh_token = RefreshToken.generate_for_user(user)
    cookies[:user_access_token] = cookie_options(max_age: 15.minutes.to_i).merge(value: access_token)
    cookies[:user_refresh_token] = cookie_options(max_age: 30.days.to_i).merge(value: refresh_token)
  end

  def set_admin_auth_cookies(admin)
    access_token = AdminAuthService.encode(admin_id: admin.id)
    refresh_token = RefreshToken.generate_for_admin(admin)
    cookies[:admin_access_token] = cookie_options(max_age: 1.hour.to_i).merge(value: access_token)
    cookies[:admin_refresh_token] = cookie_options(max_age: 30.days.to_i).merge(value: refresh_token)
  end

  def clear_user_cookies
    delete_opts = { path: '/', same_site: :lax, secure: true }
    cookies.delete(:user_access_token, **delete_opts)
    cookies.delete(:user_refresh_token, **delete_opts)
  end

  def clear_admin_cookies
    delete_opts = { path: '/', same_site: :lax, secure: true }
    cookies.delete(:admin_access_token, **delete_opts)
    cookies.delete(:admin_refresh_token, **delete_opts)
  end

  def current_user_from_cookie
    token = cookies[:user_access_token]
    return nil unless token

    decoded = AuthService.decode(token)
    User.find_by(id: decoded[:user_id]) if decoded
  end

  def current_admin_from_cookie
    token = cookies[:admin_access_token]
    return nil unless token

    decoded = AdminAuthService.decode(token)
    Admin.find_by(id: decoded[:admin_id]) if decoded
  end

  def refresh_user_session!
    raw_token = cookies[:user_refresh_token]
    rt = RefreshToken.find_by_raw_token(raw_token)
    return nil unless rt&.user

    user = rt.user
    rt.revoke!
    set_user_auth_cookies(user)
    user
  end

  def refresh_admin_session!
    raw_token = cookies[:admin_refresh_token]
    rt = RefreshToken.find_by_raw_token(raw_token)
    return nil unless rt&.admin

    admin = rt.admin
    rt.revoke!
    set_admin_auth_cookies(admin)
    admin
  end
end
