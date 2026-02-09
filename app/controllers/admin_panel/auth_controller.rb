module AdminPanel
  class AuthController < ApplicationController
    def login
      admin = Admin.find_by(email: params[:email]&.downcase)
      if admin&.authenticate(params[:password])
        token = AdminAuthService.encode(admin_id: admin.id)
        render json: { token: token, admin: { id: admin.id, email: admin.email } }
      else
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      end
    end
  end
end
