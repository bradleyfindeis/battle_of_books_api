class InviteCodeSerializer
  def initialize(code, include_teams: false)
    @code = code
    @include_teams = include_teams
  end

  def as_json(*)
    data = { id: @code.id, code: @code.code, name: @code.name, max_uses: @code.max_uses, uses_count: @code.uses_count, expires_at: @code.expires_at, active: @code.active, available: @code.available?, created_at: @code.created_at }
    if @include_teams
      data[:teams] = @code.teams.includes(:team_lead, :teammates).map { |t| TeamSerializer.new(t, admin: true).as_json }
    end
    data
  end
end
