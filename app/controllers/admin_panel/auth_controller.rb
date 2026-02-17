module AdminPanel
  class AuthController < ApplicationController
    def login
      admin = Admin.find_by(email: params[:email]&.downcase)
      if admin&.authenticate(params[:password])
        set_admin_auth_cookies(admin)
        token = AdminAuthService.encode(admin_id: admin.id)
        render json: { token: token, admin: { id: admin.id, email: admin.email } }
      else
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      end
    end

    def me
      authenticate_admin!
      return if performed?

      render json: { id: @current_admin.id, email: @current_admin.email }
    end
  end
end
