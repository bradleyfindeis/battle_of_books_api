# frozen_string_literal: true

module AdminPanel
  class BookListsController < BaseController
    before_action :set_book_list, only: [:show, :update, :destroy]

    def index
      lists = BookList.includes(:book_list_items).order(:name)
      render json: lists.map { |l| BookListSerializer.new(l, include_books: false).as_json }
    end

    def show
      render json: BookListSerializer.new(@book_list, include_books: true).as_json
    end

    def create
      list = BookList.new(book_list_params)
      if list.save
        render json: BookListSerializer.new(list, include_books: true).as_json, status: :created
      else
        render json: { errors: list.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @book_list.update(book_list_params)
        render json: BookListSerializer.new(@book_list, include_books: true).as_json
      else
        render json: { errors: @book_list.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @book_list.destroy
      head :no_content
    end

    private

    def set_book_list
      @book_list = BookList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Book list not found' }, status: :not_found
    end

    def book_list_params
      params.permit(:name)
    end
  end
end
