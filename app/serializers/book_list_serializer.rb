# frozen_string_literal: true

class BookListSerializer
  def initialize(book_list, include_books: false)
    @book_list = book_list
    @include_books = include_books
  end

  def as_json(*)
    data = {
      id: @book_list.id,
      name: @book_list.name,
      book_count: @book_list.book_list_items.count
    }
    if @include_books
      data[:books] = @book_list.book_list_items.map { |b| BookListItemSerializer.new(b).as_json }
    end
    data
  end
end
