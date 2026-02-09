class RegistrationsController < ApplicationController
  def create
    invite_code = InviteCode.find_by(code: params[:invite_code]&.upcase)
    unless invite_code&.available?
      return render json: { error: 'Invalid or expired invite code' }, status: :unprocessable_entity
    end
    password = params[:password].presence
    password_confirmation = params[:password_confirmation].presence
    if password.blank?
      return render json: { error: "Password can't be blank" }, status: :unprocessable_entity
    end
    if password.length < 6
      return render json: { error: 'Password is too short (minimum is 6 characters)' }, status: :unprocessable_entity
    end
    if password != password_confirmation
      return render json: { error: "Password confirmation doesn't match Password" }, status: :unprocessable_entity
    end
    ActiveRecord::Base.transaction do
      team = Team.create!(name: params[:team_name], invite_code: invite_code)
      user = User.new(username: params[:username], email: params[:email], role: :team_lead, team: team, pin_reset_required: false)
      user.pin_code = password
      user.save!
      invite_code.use!
      token = AuthService.encode(user_id: user.id)
      render json: { token: token, user: UserSerializer.new(user).as_json, team: TeamSerializer.new(team).as_json }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def validate_code
    invite_code = InviteCode.find_by(code: params[:code]&.upcase)
    if invite_code&.available?
      render json: { valid: true, name: invite_code.name }
    else
      render json: { valid: false }
    end
  end

  def teams
    teams = Team.select(:id, :name).order(:name)
    render json: teams.map { |t| { id: t.id, name: t.name } }
  end
end
