class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*)
    { id: @user.id, username: @user.username, email: @user.email, role: @user.role, team_id: @user.team_id, pin_reset_required: @user.pin_reset_required }
  end
end
