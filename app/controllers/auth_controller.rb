class AuthController < ApplicationController
  def login
    user = User.joins(:team).find_by(username: params[:username], team_id: params[:team_id])
    credential = params[:password].presence || params[:pin_code]
    if user&.authenticate_pin_code(credential)
      token = AuthService.encode(user_id: user.id)
      render json: { token: token, user: UserSerializer.new(user).as_json, team: TeamSerializer.new(user.team).as_json, pin_reset_required: user.pin_reset_required }
    else
      render json: { error: 'Invalid team ID, username, or password' }, status: :unauthorized
    end
  end

  def reset_pin
    authenticate_user!
    return if performed?
    if @current_user.team_lead?
      new_password = params[:new_password].presence
      if new_password.blank?
        return render json: { error: "Password can't be blank" }, status: :unprocessable_entity
      end
      if new_password.length < 6
        return render json: { error: 'Password is too short (minimum is 6 characters)' }, status: :unprocessable_entity
      end
      if @current_user.update(pin_code: new_password, pin_reset_required: false)
        render json: { message: 'Password updated successfully' }
      else
        render json: { errors: @current_user.errors }, status: :unprocessable_entity
      end
    else
      new_pin = params[:new_pin]
      unless new_pin.present? && new_pin.match?(/\A\d{4}\z/)
        return render json: { error: 'PIN must be exactly 4 digits' }, status: :unprocessable_entity
      end
      if @current_user.update(pin_code: new_pin, pin_reset_required: false)
        render json: { message: 'PIN updated successfully' }
      else
        render json: { errors: @current_user.errors }, status: :unprocessable_entity
      end
    end
  end
end
