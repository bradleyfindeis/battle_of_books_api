class BookSerializer
  def initialize(book, include_assignments: false)
    @book = book
    @include_assignments = include_assignments
  end

  def as_json(*)
    data = { id: @book.id, title: @book.title, author: @book.author, team_id: @book.team_id }
    if @include_assignments
      data[:assignments] = @book.book_assignments.includes(:user).map { |a| BookAssignmentSerializer.new(a).as_json }
    end
    data
  end
end
