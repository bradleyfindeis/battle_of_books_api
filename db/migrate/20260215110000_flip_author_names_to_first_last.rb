class FlipAuthorNamesToFirstLast < ActiveRecord::Migration[8.0]
  def up
    # Convert "Last, First" or "Last, First M." to "First M. Last"
    BookListItem.where("author LIKE '%,%'").find_each do |item|
      parts = item.author.split(',', 2).map(&:strip)
      next if parts.length < 2

      last_name = parts[0]
      first_name = parts[1]
      item.update_column(:author, "#{first_name} #{last_name}")
    end
  end

  def down
    # Convert "First Last" back to "Last, First" (best-effort for single first name)
    BookListItem.where("author NOT LIKE '%,%' AND author LIKE '% %'").find_each do |item|
      parts = item.author.strip.split(' ')
      next if parts.length < 2

      last_name = parts.last
      first_rest = parts[0..-2].join(' ')
      item.update_column(:author, "#{last_name}, #{first_rest}")
    end
  end
end
