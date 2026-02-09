class BookAssignmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_assignment, only: [:update, :destroy]

  def index
    if @current_user.team_lead?
      assignments = BookAssignment.joins(:user).where(users: { team_id: @current_user.team_id }).includes(:book, :user)
    else
      assignments = @current_user.book_assignments.includes(:book)
    end
    render json: assignments.map { |a| BookAssignmentSerializer.new(a).as_json }
  end

  def my_books
    assignments = @current_user.book_assignments.includes(:book).order(:status, :created_at)
    render json: assignments.map { |a| BookAssignmentSerializer.new(a).as_json }
  end

  def create
    require_team_lead!
    return if performed?
    user = @current_user.team.users.find_by(id: params[:user_id])
    book = @current_user.team.books.find_by(id: params[:book_id])
    unless user && book
      return render json: { error: 'User or book not found in your team' }, status: :not_found
    end
    assignment = BookAssignment.new(user: user, book: book, assigned_by: @current_user)
    if assignment.save
      render json: BookAssignmentSerializer.new(assignment).as_json, status: :created
    else
      render json: { errors: assignment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    unless @current_user.team_lead? || @assignment.user_id == @current_user.id
      return render json: { error: 'Forbidden' }, status: :forbidden
    end
    if @assignment.update(assignment_params)
      render json: BookAssignmentSerializer.new(@assignment).as_json
    else
      render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    require_team_lead!
    return if performed?
    @assignment.destroy
    head :no_content
  end

  private
  def set_assignment
    @assignment = BookAssignment.joins(:user).where(users: { team_id: @current_user.team_id }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Assignment not found' }, status: :not_found
  end
  def assignment_params
    params.permit(:status, :progress_notes)
  end
end
