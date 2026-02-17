# frozen_string_literal: true

puts "Seeding Battle of the Books..."

admin = Admin.find_or_create_by!(email: 'brad@example.com') do |a|
  a.password = 'password123'
end
puts "Admin: brad@example.com / password123"

code = InviteCode.find_or_create_by!(code: 'DEMO2025') do |c|
  c.name = 'Demo School'
  c.admin = admin
end
puts "Invite code: #{code.code}"

team = Team.find_or_create_by!(name: 'The Bookworms') do |t|
  t.invite_code = code
end

team_lead = User.find_or_create_by!(username: 'coach_smith', team: team) do |u|
  u.email = 'coach@demo.com'
  u.role = :team_lead
  u.pin_code = 'password123'
  u.pin_reset_required = false
end
puts "Team lead: coach_smith / password password123"

teammates = ['alice', 'bob', 'charlie'].map do |name|
  User.find_or_create_by!(username: name, team: team) do |u|
    u.role = :teammate
    u.pin_code = '0000'
    u.pin_reset_required = true
  end
end
puts "Teammates: alice, bob, charlie / PIN 0000"

books = []
books << Book.find_or_create_by!(title: 'Charlottes Web', team: team) { |b| b.author = 'E.B. White' }
books << Book.find_or_create_by!(title: 'Harry Potter', team: team) { |b| b.author = 'J.K. Rowling' }
books << Book.find_or_create_by!(title: 'The Lightning Thief', team: team) { |b| b.author = 'Rick Riordan' }
books << Book.find_or_create_by!(title: 'Wonder', team: team) { |b| b.author = 'R.J. Palacio' }
books << Book.find_or_create_by!(title: 'Hatchet', team: team) { |b| b.author = 'Gary Paulsen' }
puts "Books created"

BookAssignment.find_or_create_by!(user: teammates[0], book: books[0]) { |a| a.assigned_by = team_lead; a.status = :completed }
BookAssignment.find_or_create_by!(user: teammates[0], book: books[1]) { |a| a.assigned_by = team_lead; a.status = :in_progress }
BookAssignment.find_or_create_by!(user: teammates[1], book: books[0]) { |a| a.assigned_by = team_lead; a.status = :in_progress }
BookAssignment.find_or_create_by!(user: teammates[1], book: books[2]) { |a| a.assigned_by = team_lead; a.status = :assigned }
BookAssignment.find_or_create_by!(user: teammates[2], book: books[3]) { |a| a.assigned_by = team_lead; a.status = :assigned }
BookAssignment.find_or_create_by!(user: teammates[2], book: books[4]) { |a| a.assigned_by = team_lead; a.status = :assigned }
puts "Assignments created"

# Book lists (groups) for Team Lead to choose from
list_3_4 = BookList.find_or_create_by!(name: 'Medium 20 Book List 3-4 Grades 2025-26') do |l|
  # items created below
end
list_3_4_books = [
  ['Arnold, Elana K.', 'A Boy Called Bat'],
  ['Bulla, Clyde R.', 'The Chalk Box Kid'],
  ['Birney, Betty G.', 'Seven Wonders of Sassafras Springs'],
  ['Brown, Peter', 'The Wild Robot'],
  ['Byars, Betsy', 'Wanted. . . Mud Blossom'],
  ['Coville, Bruce', 'Jeremy Thatcher, Dragon Hatcher'],
  ['Creech, Sharon', 'Moo'],
  ['Draper, Sharon M.', 'Out of My Mind'],
  ['Fagan, Cary', 'Wolfie & Fly'],
  ['Guglielmo, Amy', 'Pocket Full of Colors'],
  ['Gutman, Dan', 'The Million Dollar Shot'],
  ['Hobbs, Will', 'Bearstone'],
  ['Kehret, Peg', 'Earthquake Terror'],
  ['Levine, Ellen', "Henry's Freedom Box: A True Story from the…"],
  ['Look, Lenore', 'Alvin Ho: Allergic to Girls, School and Other…'],
  ['Lord, Cynthia', 'A Handful of Stars'],
  ['Lowry, Lois', 'All About Sam'],
  ['Rappaport, Doreen', "Helen's Big World: The Life of Helen Keller"],
  ['Robinson, Barbara', 'The Best School Year Ever'],
  ['Tarshis, Lauren', 'I Survived the Sinking of the Titanic, 1912']
]
list_3_4_books.each_with_index do |(author, title), pos|
  BookListItem.find_or_create_by!(book_list: list_3_4, title: title) do |b|
    b.author = author
    b.position = pos
  end
end
puts "Book list: #{list_3_4.name} (#{list_3_4.book_list_items.count} books)"
team.update!(book_list_id: list_3_4.id)
puts "Demo team book list set to #{list_3_4.name}"

list_5_6 = BookList.find_or_create_by!(name: 'Medium 20 Book List 5-6 Grades 2025-26') do |l|
  # items created below
end
list_5_6_books = [
  ['Barnhill, Kelly', 'The Girl Who Drank the Moon'],
  ['Creech, Sharon', 'Ruby Holler'],
  ['Curtis, Christopher P.', 'Bud, Not Buddy'],
  ['DuPrau, Jeanne', 'City of Ember: the First Book of Ember'],
  ['Elliott, Zetta', 'Dragons in a Bag'],
  ['Haddix, Margaret P', 'Found'],
  ['Hale, Nathan', 'One Dead Spy: Hazardous Tales #1'],
  ['Hannigan, Katherine', 'Ida B…and Her Plans to Maximize Fun…'],
  ['Klise K. & Klise, M. Sarah', 'Regarding the Fountain: A Tale, in Letters…'],
  ['LaFaye, A.', 'Worth'],
  ['Law, Ingrid', 'Savvy'],
  ['Lord, Cynthia', 'Rules'],
  ['McSwigan, Marie', 'Snow Treasure'],
  ['Morpurgo, Michael', 'War Horse'],
  ['Nielsen, Jennifer A.', 'The False Prince'],
  ['Paterson, Katherine', 'Bridge to Terabithia'],
  ['Rowling, JK', "Harry Potter and the Sorcerer's Stone"],
  ['Ruckman, Ivy', 'Night of the Twisters'],
  ['Shurtliff, Liesl', 'Rump: The (Fairly) True Tale of Rumpelstiltskin'],
  ['Stewart, Whitney', 'Who Was Walt Disney']
]
list_5_6_books.each_with_index do |(author, title), pos|
  BookListItem.find_or_create_by!(book_list: list_5_6, title: title) do |b|
    b.author = author
    b.position = pos
  end
end
puts "Book list: #{list_5_6.name} (#{list_5_6.book_list_items.count} books)"

# Quiz questions: load from YAML seed files + inline medium questions.
# Replace all questions for these demo lists so seed is idempotent.
list_3_4.quiz_questions.destroy_all
list_5_6.quiz_questions.destroy_all

# Helper: load questions from a YAML file and create QuizQuestion records
def load_yaml_questions(book_list, yaml_path)
  items_by_title = book_list.book_list_items.index_by(&:title)
  entries = YAML.load_file(yaml_path)
  position = book_list.quiz_questions.maximum(:position) || -1

  entries.each do |entry|
    item = items_by_title[entry['book_title']]
    unless item
      puts "  WARNING: no book_list_item matching '#{entry['book_title']}' — skipping"
      next
    end
    position += 1
    QuizQuestion.create!(
      book_list: book_list,
      correct_book_list_item: item,
      question_text: entry['question_text'],
      difficulty: entry['difficulty'],
      position: position
    )
  end
end

# Load questions from YAML files (easy, medium, hard)
seed_dir = Rails.root.join('db', 'seeds')
{
  list_3_4 => %w[questions_3_4.yml questions_3_4_medium.yml questions_3_4_hard.yml],
  list_5_6 => %w[questions_5_6.yml questions_5_6_medium.yml questions_5_6_hard.yml]
}.each do |book_list, filenames|
  filenames.each do |filename|
    path = seed_dir.join(filename)
    next unless File.exist?(path)

    load_yaml_questions(book_list, path)
    puts "  Loaded #{filename}"
  end
  puts "Quiz questions: #{book_list.name} (#{book_list.quiz_questions.count} questions)"
end

puts "Done!"
