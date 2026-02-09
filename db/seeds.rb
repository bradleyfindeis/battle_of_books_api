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

# Quiz questions: 10 "In which book does...?" per book (200 per list).
# Replace all questions for these demo lists so seed is idempotent.
list_3_4.quiz_questions.destroy_all
list_5_6.quiz_questions.destroy_all

list_3_4_questions = [
  # A Boy Called Bat (10)
  ["In which book does a boy named Bat care for a baby skunk that his veterinarian mom brings home?",
   "In which book does Bat name the baby skunk Thor?",
   "In which book does a boy with autism care for an animal that was rescued?",
   "In which book does a veterinarian mom bring a baby skunk home from work?",
   "In which book does Bat want to keep a baby skunk as a pet?",
   "In which book does a boy named Bat live with his mom and sister?",
   "In which book does Bat's dad live in a different house?",
   "In which book does Bat get excited about taking care of a newborn skunk?",
   "In which book does a boy write in a notebook about caring for an animal?",
   "In which book does Bat's sister Janie have different interests than Bat?"],
  # The Chalk Box Kid (10)
  ["In which book does a boy draw pictures with chalk in a burned-out garden behind his new house?",
   "In which book does a boy move to a new house and find an old burned garden?",
   "In which book does a boy use chalk to draw plants and flowers on walls?",
   "In which book does Gregory create art in a secret place?",
   "In which book does a boy's chalk drawings surprise his family?",
   "In which book does a boy find solace in drawing after moving?",
   "In which book does a garden that burned down become a canvas for chalk?",
   "In which book does a boy draw a whole garden that never existed?",
   "In which book does Uncle Max play a role in the boy's life?",
   "In which book does a boy turn something ruined into something beautiful with chalk?"],
  # Seven Wonders of Sassafras Springs (10)
  ["In which book does a boy have to find seven wonders in his small town of Sassafras Springs?",
   "In which book does Eben have one week to find seven wonders close to home?",
   "In which book does a boy think his town is too boring until he starts looking?",
   "In which book does finding wonders earn a boy a train ticket to Colorado?",
   "In which book does a boy discover wonders in his own small town?",
   "In which book does Colleen tell Eben stories that change his view?",
   "In which book does a boy learn that wonders can be found anywhere?",
   "In which book is Sassafras Springs the setting for a wonder hunt?",
   "In which book does a boy's pa challenge him to find seven wonders?",
   "In which book do ordinary people's stories become seven wonders?"],
  # The Wild Robot (10)
  ["In which book does a robot named Roz wash ashore on an island and learn to survive with animal friends?",
   "In which book does a robot adopt an orphaned gosling?",
   "In which book does Roz learn to speak animal languages?",
   "In which book does a robot become a mother to a goose?",
   "In which book is a robot's shipwreck the start of a new life?",
   "In which book do animals first fear then befriend a robot?",
   "In which book does a robot build a home on an island?",
   "In which book is Brightbill the name of a young goose?",
   "In which book does a robot face winter and predators to protect her family?",
   "In which book might RECOs come to take a robot back?"],
  # Wanted. . . Mud Blossom (10)
  ["In which book is a dog named Mud Blossom wanted for a crime the family tries to solve?",
   "In which book does the Blossom family try to clear their dog's name?",
   "In which book is Mud Blossom a dog who gets into trouble?",
   "In which book does a family mystery involve their pet dog?",
   "In which book are the Blossom kids trying to solve a mystery?",
   "In which book does a dog become the main suspect in a family incident?",
   "In which book do the Blossoms work together to find the real culprit?",
   "In which book is Mud Blossom wanted by the family for something he did?",
   "In which book does a family have a dog named Mud Blossom?",
   "In which book do the Blossom family members have distinct personalities and roles?"],
  # Jeremy Thatcher, Dragon Hatcher (10)
  ["In which book does a boy named Jeremy hatch a small dragon from a magical egg he buys in a strange shop?",
   "In which book does Jeremy find a mysterious shop and leave with a dragon egg?",
   "In which book does a small dragon become a boy's secret pet?",
   "In which book does Mary Lou Hutton share a secret about dragons?",
   "In which book must a dragon be returned to its own world when it grows?",
   "In which book does a boy draw and care for a dragon in his bedroom?",
   "In which book is there a shop that appears when you need it?",
   "In which book does Tiamat become a dragon that must go home?",
   "In which book does a boy have to say goodbye to his dragon?",
   "In which book does Jeremy Thatcher discover he is a dragon hatcher?"],
  # Moo (10)
  ["In which book does a girl named Reena move to Maine and end up caring for a stubborn cow?",
   "In which book does Reena's family move from the city to Maine?",
   "In which book does a girl have to work on a farm with a cow named Zora?",
   "In which book does Zora the cow cause trouble for the family?",
   "In which book does Reena learn about farm life the hard way?",
   "In which book does a city girl become responsible for a stubborn animal?",
   "In which book is Zora a cow that needs to be cared for?",
   "In which book does a move to the country involve a cow?",
   "In which book does Reena write letters about her new life?",
   "In which book does a family's new beginning include a difficult cow?"],
  # Out of My Mind (10)
  ["In which book does a brilliant girl who cannot speak or walk use a board to communicate with the world?",
   "In which book is Melody unable to speak but has a photographic memory?",
   "In which book does a girl use a Medi-Talker to communicate?",
   "In which book does Melody compete on a quiz team despite her disability?",
   "In which book is a girl in a wheelchair smarter than almost everyone?",
   "In which book do classmates sometimes underestimate Melody?",
   "In which book does a girl finally get a way to show how smart she is?",
   "In which book does Catherine help Melody at school?",
   "In which book does a trip to the quiz competition go wrong?",
   "In which book is the phrase 'out of my mind' redefined by the main character?"],
  # Wolfie & Fly (10)
  ["In which book do a girl nicknamed Wolfie and a boy named Fly build a cardboard submarine and have adventures?",
   "In which book does a girl who likes to be alone meet a boy named Fly?",
   "In which book do two kids turn a cardboard box into a submarine?",
   "In which book does Wolfie learn that friends can be fun?",
   "In which book do Wolfie and Fly have an imaginary underwater adventure?",
   "In which book is Livingston the name of Fly's pet?",
   "In which book does a girl prefer reading until Fly comes along?",
   "In which book do two neighbors build something from cardboard?",
   "In which book does a submarine adventure happen in a backyard?",
   "In which book are Wolfie and Fly the main characters' nicknames?"],
  # Pocket Full of Colors (10)
  ["In which book does a girl grow up to become a Disney artist who paints with a pocket full of colors?",
   "In which book is Mary Blair the main character who becomes a Disney artist?",
   "In which book does a woman paint with bold colors for Disney?",
   "In which book does an artist work on Cinderella and Alice in Wonderland?",
   "In which book does a girl carry colors in her pocket?",
   "In which book does an artist's unique style change Disney animation?",
   "In which book is the true story of a Disney Imagineer?",
   "In which book does color play a huge role in the main character's life?",
   "In which book does a woman break barriers at the Disney studio?",
   "In which book does an artist inspire the It's a Small World design?"],
  # The Million Dollar Shot (10)
  ["In which book does a boy get the chance to shoot one free throw at a Fling game for a million dollars?",
   "In which book does Eddie get a million-dollar shot at a basketball game?",
   "In which book does a boy practice free throws for a big contest?",
   "In which book could one shot change a family's life?",
   "In which book is the Fling a soda company sponsoring a contest?",
   "In which book does a boy live in a trailer park with his mom?",
   "In which book does a best friend help with practice?",
   "In which book is a million dollars won or lost on one shot?",
   "In which book does Eddie face pressure from many people?",
   "In which book does a basketball free throw contest mean everything?"],
  # Bearstone (10)
  ["In which book does a boy named Cloyd find a blue bear stone and work on a ranch in the wilderness?",
   "In which book does Cloyd go to live with an old man in the mountains?",
   "In which book is there a sacred bear stone that connects to heritage?",
   "In which book does a Ute boy find a new life on a ranch?",
   "In which book does Walter Landis take in Cloyd?",
   "In which book does a boy discover a bear stone in a cave?",
   "In which book does Cloyd learn about his Native American heritage?",
   "In which book does a boy help with ranch work and find a precious stone?",
   "In which book is the setting a remote mountain ranch?",
   "In which book does a blue stone hold special meaning for Cloyd?"],
  # Earthquake Terror (10)
  ["In which book are a brother and sister trapped by an earthquake on an island campground?",
   "In which book does Jonathan try to get his sister and himself to safety after an earthquake?",
   "In which book is Abby disabled and in a wheelchair during a disaster?",
   "In which book does a bridge collapse in an earthquake?",
   "In which book are two kids alone on an island after a quake?",
   "In which book does Jonathan have to be brave for his sister?",
   "In which book is Magpie Island the setting for survival?",
   "In which book do a brother and sister face nature's fury?",
   "In which book does an earthquake strand children on an island?",
   "In which book must a boy find a way to cross a damaged bridge?"],
  # Henry's Freedom Box (10)
  ["In which book does a man mail himself in a wooden crate to escape slavery?",
   "In which book does Henry Brown escape to freedom in a box?",
   "In which book is Henry Brown the true story of a slave's escape?",
   "In which book does a man ship himself north in a crate?",
   "In which book do friends help mail a man to freedom?",
   "In which book does Henry become Henry Box Brown?",
   "In which book is the Underground Railroad part of the story?",
   "In which book does a man risk everything in a wooden box?",
   "In which book is the journey in a box dangerous and long?",
   "In which book does Henry finally get a birthday after freedom?"],
  # Alvin Ho (10)
  ["In which book is a boy allergic to girls, school, and a long list of other scary things?",
   "In which book does Alvin Ho fear everything and carry a PDK?",
   "In which book is Alvin afraid of school and many other things?",
   "In which book does a boy have a Personal Disaster Kit?",
   "In which book is the setting Concord, Massachusetts?",
   "In which book does Alvin try to get a friend in second grade?",
   "In which book does a boy's family try to help him with his fears?",
   "In which book is Alvin allergic to the list in the title?",
   "In which book does a scared boy have humorous adventures?",
   "In which book does Alvin Ho love Paul Revere and superheroes?"],
  # A Handful of Stars (10)
  ["In which book does a girl's dog run away and she become friends with a migrant worker while searching for blueberries?",
   "In which book does Lucky the dog run into the blueberry barrens?",
   "In which book does Lily meet Salma when searching for her dog?",
   "In which book do two girls from different backgrounds become friends?",
   "In which book does a girl help paint bee boxes for a contest?",
   "In which book is the setting Maine and blueberry harvesting?",
   "In which book does a runaway dog lead to an unexpected friendship?",
   "In which book does Salma's family work picking blueberries?",
   "In which book do Lily and Salma work together on a project?",
   "In which book is a handful of stars part of a special moment?"],
  # All About Sam (10)
  ["In which book is Sam a little boy who gets into mischief and drives his family a bit crazy?",
   "In which book does Sam Krupnik get into one scrape after another?",
   "In which book is Anastasia's little brother the main character?",
   "In which book does a little boy have big ideas that cause trouble?",
   "In which book does Sam want to change his name?",
   "In which book does a preschooler keep his family on their toes?",
   "In which book is Sam the younger brother in the Krupnik family?",
   "In which book do Sam's antics make his parents exasperated?",
   "In which book does a little boy have a unique view of the world?",
   "In which book is the sequel about Anastasia's brother Sam?"],
  # Helen's Big World (10)
  ["In which book do we learn the true story of a girl who was deaf and blind but learned to communicate with the world?",
   "In which book is Helen Keller's life told for young readers?",
   "In which book does Annie Sullivan help a girl learn to communicate?",
   "In which book does Helen learn to spell words into her hand?",
   "In which book is water from a pump a breakthrough moment?",
   "In which book does a girl overcome being deaf and blind?",
   "In which book is Helen's world described as big despite her disabilities?",
   "In which book does Helen Keller become an inspiration?",
   "In which book is the true story of Helen and her teacher?",
   "In which book does a child discover language through touch?"],
  # The Best School Year Ever (10)
  ["In which book do the Herdman kids make the best school year ever for their class?",
   "In which book are the Herdmans the worst kids in the history of the world?",
   "In which book does each student have to say something nice about the Herdmans?",
   "In which book do the Herdman kids surprise everyone?",
   "In which book is the assignment to find good in the Herdmans?",
   "In which book does a class learn about the Herdman family?",
   "In which book do the most misbehaved kids turn the year around?",
   "In which book is Woodrow Wilson Elementary the school?",
   "In which book do the Herdmans have a positive impact despite everything?",
   "In which book does the narrator realize the Herdmans have good qualities?"],
  # I Survived the Sinking of the Titanic, 1912 (10)
  ["In which book does a boy named George survive the sinking of the Titanic in 1912?",
   "In which book does George sail on the Titanic with his sister and aunt?",
   "In which book does a boy experience the Titanic disaster?",
   "In which book does George try to find his family when the ship sinks?",
   "In which book is the Titanic the setting for a survival story?",
   "In which book does a young stowaway face the sinking ship?",
   "In which book is 1912 the year of the disaster?",
   "In which book does George end up in a lifeboat?",
   "In which book is the unsinkable ship the Titanic?",
   "In which book does a boy survive one of history's worst shipwrecks?"]
]
list_3_4.book_list_items.order(:position).each_with_index do |item, book_pos|
  questions_for_book = list_3_4_questions[book_pos]
  questions_for_book.each_with_index do |question_text, q_pos|
    pos = book_pos * 10 + q_pos
    QuizQuestion.create!(book_list: list_3_4, correct_book_list_item: item, question_text: question_text, position: pos)
  end
end
puts "Quiz questions: #{list_3_4.name} (#{list_3_4.quiz_questions.count} questions)"

list_5_6_questions = [
  # The Girl Who Drank the Moon (10)
  ["In which book does a witch accidentally feed a baby moonlight and give her magical powers?",
   "In which book does Luna have magic that grows as she gets older?",
   "In which book does a witch named Xan rescue babies from a village?",
   "In which book is the forest full of magical creatures?",
   "In which book does a girl's magic need to be bound until her birthday?",
   "In which book does a dragon and a swamp monster help raise a child?",
   "In which book is the Protectorate a place that fears the witch?",
   "In which book does feeding a baby moonlight create a powerful witch?",
   "In which book does Luna discover who she really is?",
   "In which book is there a volcano that holds a secret?"],
  # Ruby Holler (10)
  ["In which book do twins named Florida and Dallas go to live with an older couple in a place called Ruby Holler?",
   "In which book are Florida and Dallas twins who have been in foster care?",
   "In which book do Tiller and Sairy take in troubled kids?",
   "In which book is Ruby Holler a peaceful place for a fresh start?",
   "In which book do the twins go on a river adventure with the elderly couple?",
   "In which book have Florida and Dallas had bad experiences in foster homes?",
   "In which book does a holler become a place of healing?",
   "In which book do the twins learn to trust Tiller and Sairy?",
   "In which book is there a treasure map and a river trip?",
   "In which book do Dallas and Florida find a real home in the holler?"],
  # Bud, Not Buddy (10)
  ["In which book does a boy named Bud search for his father during the Great Depression with a flyer and a suitcase?",
   "In which book does Bud carry rules for life in his suitcase?",
   "In which book does a boy think Herman E. Calloway is his father?",
   "In which book does Bud travel to Grand Rapids looking for family?",
   "In which book is the Dusky Devastators of the Depression a band?",
   "In which book does a boy escape from foster care to find his dad?",
   "In which book does Bud meet Lefty Lewis on his journey?",
   "In which book is 1936 Michigan the setting?",
   "In which book does a boy insist his name is Bud not Buddy?",
   "In which book does Bud find a family in a jazz band?"],
  # City of Ember (10)
  ["In which book do two kids named Lina and Doon try to save their underground city when the lights start failing?",
   "In which book is Ember an underground city running out of power?",
   "In which book does Lina want to be a messenger?",
   "In which book does Doon work in the pipeworks?",
   "In which book do Lina and Doon find an old instruction that might save the city?",
   "In which book do the streetlights flicker and go out?",
   "In which book is the generator failing and no one knows how to fix it?",
   "In which book do two friends discover the way out of Ember?",
   "In which book was the city built to survive a disaster?",
   "In which book does a beetle lead to an important discovery?"],
  # Dragons in a Bag (10)
  ["In which book does a boy named Jax have to deliver three baby dragons through Brooklyn?",
   "In which book does Jax meet a witch who sends him on a delivery?",
   "In which book are baby dragons in a bag that must stay warm?",
   "In which book does Jax have to get dragons to a portal in Brooklyn?",
   "In which book does a boy's mom leave him with a strange babysitter?",
   "In which book are the dragons not allowed to eat sugar?",
   "In which book does Jax have help from new friends?",
   "In which book must dragons be returned to their world?",
   "In which book is Brooklyn the setting for a magical delivery?",
   "In which book does Jax discover he has a role in the magical world?"],
  # Found (10)
  ["In which book do kids discover a plane that landed with only babies and no pilot?",
   "In which book does Jonah find out he was one of the babies on the plane?",
   "In which book do Chip and Jonah receive mysterious letters?",
   "In which book are children from the 1930s missing from history?",
   "In which book does a plane appear with no pilot and only babies?",
   "In which book is there a conspiracy about missing children?",
   "In which book do Jonah and Chip try to find out their true past?",
   "In which book does time travel affect the characters?",
   "In which book is the first in the Missing series?",
   "In which book do kids discover they were adopted from the past?"],
  # One Dead Spy (10)
  ["In which book does the real Nathan Hale tell his story as a spy during the American Revolution?",
   "In which book does Nathan Hale the spy narrate from the gallows?",
   "In which book does the hangman interrupt with humor and facts?",
   "In which book is the American Revolution told in graphic novel form?",
   "In which book does Nathan Hale tell stories of the Revolution?",
   "In which book is Hazardous Tales the series name?",
   "In which book does a spy face execution but tell stories first?",
   "In which book are history and humor combined?",
   "In which book does the author use the name Nathan Hale for the narrator?",
   "In which book does one dead spy come back to tell the tale?"],
  # Ida B (10)
  ["In which book does a girl named Ida B have plans to maximize fun until her mom gets sick?",
   "In which book does Ida B talk to trees and the brook?",
   "In which book does Ida B's mom get cancer?",
   "In which book must part of the family orchard be sold?",
   "In which book does Ida B resist going back to school?",
   "In which book does a girl have to share her teacher with other kids?",
   "In which book does Ida B's heart harden when life changes?",
   "In which book is Ida B's full name Ida Elizabeth?",
   "In which book does a girl learn to open her heart again?",
   "In which book does Ida B have plans that get interrupted by illness?"],
  # Regarding the Fountain (10)
  ["In which book does a town try to fix a leaky fountain using letters and memos?",
   "In which book is the story told entirely in letters and documents?",
   "In which book does Florence Waters design a new fountain?",
   "In which book does a school have a leaky drinking fountain?",
   "In which book do students and teachers write letters about a fountain?",
   "In which book is the format epistolary for young readers?",
   "In which book does the town of Dry Creek need a new fountain?",
   "In which book do memos and letters reveal the plot?",
   "In which book is Florence Waters an eccentric designer?",
   "In which book does a fountain project get complicated by letters?"],
  # Worth (10)
  ["In which book does an orphan named Nate learn what he is worth after the Civil War?",
   "In which book does Nate live with his uncle after the war?",
   "In which book does a boy work on a farm and face prejudice?",
   "In which book does John Worth befriend Nate?",
   "In which book is the setting post-Civil War America?",
   "In which book does a boy discover his own value?",
   "In which book does Nate face challenges as an orphan?",
   "In which book is worth both a name and a theme?",
   "In which book does a boy find his place after losing family?",
   "In which book does Nate learn about worth from John?"],
  # Savvy (10)
  ["In which book does a girl named Mibs turn thirteen and discover her supernatural savvy on a bus?",
   "In which book does each family member get a special power on their thirteenth birthday?",
   "In which book does Mibs think her savvy might wake up her hurt father?",
   "In which book do kids run away on a bus to get to the hospital?",
   "In which book does Grandpa move hurricanes and Momma does everything right?",
   "In which book does a birthday bring a surprising power?",
   "In which book is the bus trip to Salina important?",
   "In which book does Mibs have a savvy she doesn't understand at first?",
   "In which book do the Beaumont family have special talents?",
   "In which book does turning thirteen change everything for Mibs?"],
  # Rules (10)
  ["In which book does a girl named Catherine make rules for her brother who has autism?",
   "In which book does Catherine have a brother named David who has autism?",
   "In which book does Catherine make rules like 'no toys in the fish tank'?",
   "In which book does Catherine become friends with a boy in a wheelchair?",
   "In which book does Jason use a communication book?",
   "In which book does Catherine sometimes feel embarrassed by David?",
   "In which book does a girl learn about acceptance?",
   "In which book is David's behavior explained through rules?",
   "In which book does Catherine want a normal life?",
   "In which book do rules help Catherine cope with her brother?"],
  # Snow Treasure (10)
  ["In which book do Norwegian children sneak gold past Nazi soldiers on their sleds?",
   "In which book do kids hide gold in the snow during World War II?",
   "In which book does Peter lead the children in a dangerous mission?",
   "In which book must Norwegian gold be moved to a ship?",
   "In which book do Nazis occupy Norway and the kids help resist?",
   "In which book do children sled past soldiers with gold hidden?",
   "In which book is the setting Norway in winter during WWII?",
   "In which book does Uncle Victor help with the plan?",
   "In which book do kids risk their lives for their country?",
   "In which book is snow the key to hiding the treasure?"],
  # War Horse (10)
  ["In which book is a horse named Joey the narrator of his own story during World War I?",
   "In which book does Joey go from a farm to the war?",
   "In which book does Albert promise to find his horse Joey?",
   "In which book is the story told from the horse's point of view?",
   "In which book does a horse serve on both sides in the war?",
   "In which book does Joey face tanks and trenches?",
   "In which book is World War I seen through a horse's eyes?",
   "In which book does a horse have different owners during the war?",
   "In which book does Joey end up in no man's land?",
   "In which book might Albert and Joey be reunited?"],
  # The False Prince (10)
  ["In which book is an orphan named Sage trained to pretend he is a lost prince?",
   "In which book does Conner gather orphans for a dangerous plan?",
   "In which book must one boy be chosen to impersonate the prince?",
   "In which book does Sage have a secret that could change everything?",
   "In which book is the kingdom of Carthya missing its princes?",
   "In which book does a nobleman need a false prince?",
   "In which book does Sage compete with other boys for the role?",
   "In which book are the princes believed dead?",
   "In which book does Sage have a defiant personality?",
   "In which book is the Ascendance Trilogy the series?"],
  # Bridge to Terabithia (10)
  ["In which book do two friends create a secret kingdom called Terabithia in the woods?",
   "In which book do Jess and Leslie rule as king and queen in the woods?",
   "In which book does Leslie die in a tragic accident?",
   "In which book does Jess build a bridge to Terabithia?",
   "In which book do two outsiders become best friends?",
   "In which book is Terabithia an imaginary kingdom?",
   "In which book does Jess struggle with grief and loss?",
   "In which book does running in the woods lead to imagination?",
   "In which book do they swing across a creek to reach Terabithia?",
   "In which book does a bridge become important after a tragedy?"],
  # Harry Potter and the Sorcerer's Stone (10)
  ["In which book does a boy find out he is a wizard when he turns eleven?",
   "In which book does Harry Potter go to Hogwarts School?",
   "In which book does Harry meet Ron and Hermione?",
   "In which book is the Sorcerer's Stone protected at Hogwarts?",
   "In which book does Harry discover he is famous in the wizarding world?",
   "In which book does Harry live under the stairs at the Dursleys?",
   "In which book does Harry play Quidditch for the first time?",
   "In which book does Voldemort try to get the Stone?",
   "In which book is Platform Nine and Three-Quarters introduced?",
   "In which book does Harry have a lightning bolt scar?"],
  # Night of the Twisters (10)
  ["In which book does a boy named Dan Hatch survive a night of terrible tornadoes?",
   "In which book do multiple tornadoes hit one town in one night?",
   "In which book does Dan try to protect his baby brother?",
   "In which book is the setting Nebraska during a tornado outbreak?",
   "In which book does Dan's family take shelter in the basement?",
   "In which book do friends try to find each other after the storms?",
   "In which book is the night full of terrifying twisters?",
   "In which book does Dan face one tornado after another?",
   "In which book is the story inspired by real events?",
   "In which book does a boy survive a night of destruction?"],
  # Rump (10)
  ["In which book can a boy named Rump spin straw into gold?",
   "In which book does Rump discover his name is part of a curse?",
   "In which book does a boy have a magical talent for spinning?",
   "In which book does Rump live with his grandmother in a mining village?",
   "In which book is the story a twist on Rumpelstiltskin?",
   "In which book does Rump try to find his full name?",
   "In which book do the miller's daughter and the king play a part?",
   "In which book can straw be spun into gold by the main character?",
   "In which book does Rump make a dangerous deal?",
   "In which book is the 'fairly true tale' of Rumpelstiltskin?"],
  # Who Was Walt Disney (10)
  ["In which book do we learn the life story of the man who created Mickey Mouse?",
   "In which book is Walt Disney's biography for young readers?",
   "In which book did the creator of Mickey Mouse grow up on a farm?",
   "In which book did Walt Disney face failure before success?",
   "In which book is the Who Was series biography of Disney?",
   "In which book do we learn how Disneyland was created?",
   "In which book is animation history part of the story?",
   "In which book did Walt Disney have a brother named Roy?",
   "In which book do we learn about Steamboat Willie?",
   "In which book is the man who created Mickey Mouse the subject?"]
]
list_5_6.book_list_items.order(:position).each_with_index do |item, book_pos|
  questions_for_book = list_5_6_questions[book_pos]
  questions_for_book.each_with_index do |question_text, q_pos|
    pos = book_pos * 10 + q_pos
    QuizQuestion.create!(book_list: list_5_6, correct_book_list_item: item, question_text: question_text, position: pos)
  end
end
puts "Quiz questions: #{list_5_6.name} (#{list_5_6.quiz_questions.count} questions)"

puts "Done!"
