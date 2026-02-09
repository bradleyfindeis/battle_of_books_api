# frozen_string_literal: true

class BookListsController < ApplicationController
  before_action :authenticate_user!

  def index
    lists = BookList.includes(:book_list_items).order(:name)
    render json: lists.map { |l| BookListSerializer.new(l, include_books: true).as_json }
  end
end
