# frozen_string_literal: true

module AdminPanel
  class BookListItemsController < BaseController
    before_action :set_book_list
    before_action :set_book_list_item, only: [:update, :destroy]

    def create
      item = @book_list.book_list_items.build(book_list_item_params)
      item.position = (@book_list.book_list_items.maximum(:position) || 0) + 1
      if item.save
        render json: BookListItemSerializer.new(item).as_json, status: :created
      else
        render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @item.update(book_list_item_params)
        render json: BookListItemSerializer.new(@item).as_json
      else
        render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @item.destroy
      head :no_content
    end

    private

    def set_book_list
      @book_list = BookList.find(params[:book_list_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Book list not found' }, status: :not_found
    end

    def set_book_list_item
      @item = @book_list.book_list_items.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Book not found' }, status: :not_found
    end

    def book_list_item_params
      params.permit(:title, :author)
    end
  end
end
