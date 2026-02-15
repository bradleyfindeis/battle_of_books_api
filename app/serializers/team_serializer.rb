class TeamSerializer
  def initialize(team, admin: false, include_details: false)
    @team = team
    @admin = admin
    @include_details = include_details
  end

  def as_json(*)
    data = { id: @team.id, name: @team.name, created_at: @team.created_at, teammate_count: @team.teammates.size }
    data[:book_list_id] = @team.book_list_id
    data[:book_list] = @team.book_list ? { id: @team.book_list.id, name: @team.book_list.name } : nil
    data[:leaderboard_enabled] = @team.leaderboard_enabled
    if @admin
      data[:invite_code] = @team.invite_code&.code
      data[:invite_code_id] = @team.invite_code_id
      data[:team_lead] = @team.team_lead ? UserSerializer.new(@team.team_lead).as_json : nil
    end
    if @include_details
      data[:teammates] = @team.teammates.map { |t| UserSerializer.new(t).as_json }
      data[:books] = @team.books.map { |b| BookSerializer.new(b).as_json }
    end
    data
  end
end
