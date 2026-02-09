class BookAssignmentSerializer
  def initialize(assignment, include_book: true)
    @assignment = assignment
    @include_book = include_book
  end

  def as_json(*)
    data = { id: @assignment.id, user_id: @assignment.user_id, book_id: @assignment.book_id, assigned_by_id: @assignment.assigned_by_id, status: @assignment.status, progress_notes: @assignment.progress_notes, created_at: @assignment.created_at, updated_at: @assignment.updated_at }
    data[:book] = BookSerializer.new(@assignment.book).as_json if @include_book
    data[:user] = { id: @assignment.user_id, username: @assignment.user.username }
    data
  end
end
