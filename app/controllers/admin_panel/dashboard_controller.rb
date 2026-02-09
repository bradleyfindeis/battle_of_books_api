module AdminPanel
  class DashboardController < BaseController
    DEMO_TEAM_NAME = 'The Bookworms'
    DEMO_USERNAME = 'demo_teammate'
    DEMO_BOOK_LIST_NAME = 'Medium 20 Book List 3-4 Grades 2025-26'

    def stats
      render json: {
        total_teams: Team.count,
        total_users: User.count,
        total_team_leads: User.team_lead.count,
        total_teammates: User.teammate.count,
        total_books: Book.count,
        total_assignments: BookAssignment.count,
        assignments_by_status: {
          assigned: BookAssignment.assigned.count,
          in_progress: BookAssignment.in_progress.count,
          completed: BookAssignment.completed.count
        },
        active_invite_codes: InviteCode.available.count,
        teams_created_this_week: Team.where('created_at > ?', 1.week.ago).count
      }
    end

    def demo_teammate
      team = Team.find_by(name: DEMO_TEAM_NAME) || Team.first
      unless team
        return render json: { error: 'No team found. Run seeds first.' }, status: :unprocessable_entity
      end

      book_list = BookList.find_by(name: DEMO_BOOK_LIST_NAME)
      unless book_list
        return render json: { error: "Book list '#{DEMO_BOOK_LIST_NAME}' not found. Run seeds first." }, status: :unprocessable_entity
      end

      team_lead = team.team_lead
      unless team_lead
        return render json: { error: 'Seeded team has no team lead. Run seeds first.' }, status: :unprocessable_entity
      end

      demo_user = User.find_or_create_by!(username: DEMO_USERNAME, team: team) do |u|
        u.role = :teammate
        u.pin_code = '0000'
        u.pin_reset_required = false
      end

      book_list.book_list_items.limit(5).each do |item|
        book = Book.find_or_create_by!(team: team, title: item.title) do |b|
          b.author = item.author
        end
        BookAssignment.find_or_create_by!(user: demo_user, book: book) do |a|
          a.assigned_by = team_lead
          a.status = :assigned
        end
      end

      token = AuthService.encode(user_id: demo_user.id)
      render json: {
        token: token,
        user: UserSerializer.new(demo_user).as_json,
        team: TeamSerializer.new(team).as_json,
        pin_reset_required: demo_user.pin_reset_required
      }
    end
  end
end
