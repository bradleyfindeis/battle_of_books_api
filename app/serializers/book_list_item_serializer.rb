# frozen_string_literal: true

class BookListItemSerializer
  def initialize(item)
    @item = item
  end

  def as_json(*)
    { id: @item.id, title: @item.title, author: @item.author }
  end
end
