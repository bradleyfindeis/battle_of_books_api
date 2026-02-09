class BooksController < ApplicationController
  before_action :authenticate_user!
  before_action :require_team_lead!, except: [:index]
  before_action :set_book, only: [:update, :destroy]

  def index
    books = @current_user.team.books.includes(book_assignments: :user)
    render json: books.map { |b| BookSerializer.new(b, include_assignments: true).as_json }
  end

  def create
    book = @current_user.team.books.build(book_params)
    if book.save
      render json: BookSerializer.new(book).as_json, status: :created
    else
      render json: { errors: book.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @book.update(book_params)
      render json: BookSerializer.new(@book).as_json
    else
      render json: { errors: @book.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    head :no_content
  end

  private
  def set_book
    @book = @current_user.team.books.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Book not found' }, status: :not_found
  end
  def book_params
    params.permit(:title, :author)
  end
end
