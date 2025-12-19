# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Clear existing data
# Clear existing data
puts "🗑️  Clearing database..."
Review.destroy_all
Borrowing.destroy_all
Reservation.destroy_all
BookAuthor.destroy_all
BookCategory.destroy_all
Profile.destroy_all
Book.destroy_all
Author.destroy_all
Category.destroy_all
Tag.destroy_all
User.destroy_all

puts "✅ Database cleared!"
puts "\n" + "="*50

# Create Users
puts "👥 Creating users..."

librarian = User.create!(
  name: "Admin Librarian",
  email: "admin@library.com",
  password: "password123",
  password_confirmation: "password123",
  role: :librarian,
  phone: "1234567890",
  membership_date: Date.today - 365.days
)

member1 = User.create!(
  name: "John Doe",
  email: "john@example.com",
  password: "password123",
  password_confirmation: "password123",
  role: :member,
  phone: "9876543210",
  membership_date: Date.today - 90.days
)

member2 = User.create!(
  name: "Jane Smith",
  email: "jane@example.com",
  password: "password123",
  password_confirmation: "password123",
  role: :member,
  phone: "5555555555",
  membership_date: Date.today - 60.days
)

member3 = User.create!(
  name: "Bob Johnson",
  email: "bob@example.com",
  password: "password123",
  password_confirmation: "password123",
  role: :member,
  phone: "7778889999",
  membership_date: Date.today - 30.days
)

member4 = User.create!(
  name: "Alice Williams",
  email: "alice@example.com",
  password: "password123",
  password_confirmation: "password123",
  role: :member,
  phone: "4445556666",
  membership_date: Date.today - 15.days
)

puts "✅ Created #{User.count} users (#{User.librarian.count} librarians, #{User.member.count} members)"

# Create Categories
puts "\n📚 Creating categories..."

fiction = Category.create!(name: "Fiction")
non_fiction = Category.create!(name: "Non-Fiction")
mystery = Category.create!(name: "Mystery")
thriller = Category.create!(name: "Thriller")
scifi = Category.create!(name: "Science Fiction")
fantasy = Category.create!(name: "Fantasy")
romance = Category.create!(name: "Romance")
biography = Category.create!(name: "Biography")
history = Category.create!(name: "History")
self_help = Category.create!(name: "Self Help")
classic = Category.create!(name: "Classic")
young_adult = Category.create!(name: "Young Adult")
horror = Category.create!(name: "Horror")
poetry = Category.create!(name: "Poetry")
adventure = Category.create!(name: "Adventure")

puts "✅ Created #{Category.count} categories"

# Create Tags
puts "\n🏷️  Creating tags..."

bestseller = Tag.create!(name: "Bestseller")
award_winner = Tag.create!(name: "Award Winner")
classic_tag = Tag.create!(name: "Classic")
new_release = Tag.create!(name: "New Release")
recommended = Tag.create!(name: "Staff Recommended")
popular = Tag.create!(name: "Popular")
limited_edition = Tag.create!(name: "Limited Edition")

puts "✅ Created #{Tag.count} tags"

# Create Authors
puts "\n✍️  Creating authors..."

author1 = Author.create!(
  name: "J.K. Rowling",
  biography: "British author, best known for the Harry Potter fantasy series. The books have won multiple awards and sold more than 500 million copies.",
  birth_date: Date.new(1965, 7, 31)
)

author2 = Author.create!(
  name: "George R.R. Martin",
  biography: "American novelist and short story writer in the fantasy, horror, and science fiction genres. Best known for A Song of Ice and Fire.",
  birth_date: Date.new(1948, 9, 20)
)

author3 = Author.create!(
  name: "Agatha Christie",
  biography: "English writer known for her 66 detective novels. She is the best-selling novelist of all time.",
  birth_date: Date.new(1890, 9, 15)
)

author4 = Author.create!(
  name: "Isaac Asimov",
  biography: "American writer and professor of biochemistry, known for his works of science fiction and popular science.",
  birth_date: Date.new(1920, 1, 2)
)

author5 = Author.create!(
  name: "Jane Austen",
  biography: "English novelist known primarily for her six major novels which critique the British landed gentry.",
  birth_date: Date.new(1775, 12, 16)
)

author6 = Author.create!(
  name: "Stephen King",
  biography: "American author of horror, supernatural fiction, suspense, crime, science-fiction, and fantasy novels.",
  birth_date: Date.new(1947, 9, 21)
)

author7 = Author.create!(
  name: "Margaret Atwood",
  biography: "Canadian poet, novelist, literary critic, essayist, teacher, environmental activist, and inventor.",
  birth_date: Date.new(1939, 11, 18)
)

author8 = Author.create!(
  name: "Ernest Hemingway",
  biography: "American novelist, short-story writer, and journalist. His economical style had a strong influence on 20th-century fiction.",
  birth_date: Date.new(1899, 7, 21)
)

author9 = Author.create!(
  name: "Toni Morrison",
  biography: "American novelist. Her novels are known for their epic themes, vivid dialogue, and richly detailed African-American characters.",
  birth_date: Date.new(1931, 2, 18)
)

author10 = Author.create!(
  name: "Gabriel García Márquez",
  biography: "Colombian novelist, short-story writer, screenwriter, and journalist, known as one of the most significant writers of the 20th century.",
  birth_date: Date.new(1927, 3, 6)
)

puts "✅ Created #{Author.count} authors"

# Create Books
puts "\n📖 Creating books..."

book1 = Book.create!(
  title: "Harry Potter and the Philosopher's Stone",
  isbn: "9780747532699",
  publication_year: 1997,
  total_copies: 8,
  available_copies: 5,
  description: "Harry Potter has never even heard of Hogwarts when the letters start dropping on the doormat at number four, Privet Drive. Young Harry discovers he is a wizard and begins his magical education."
)
book1.authors << author1
book1.categories << [ fiction, fantasy, young_adult ]
book1.tags << [ bestseller, recommended, popular ]

book2 = Book.create!(
  title: "Harry Potter and the Chamber of Secrets",
  isbn: "9780747538493",
  publication_year: 1998,
  total_copies: 6,
  available_copies: 6,
  description: "The Dursleys were so mean and hideous that summer that all Harry Potter wanted was to get back to the Hogwarts School for Witchcraft and Wizardry."
)
book2.authors << author1
book2.categories << [ fiction, fantasy, young_adult ]
book2.tags << [ bestseller, popular ]

book3 = Book.create!(
  title: "A Game of Thrones",
  isbn: "9780553103540",
  publication_year: 1996,
  total_copies: 5,
  available_copies: 2,
  description: "The first book in the epic fantasy series A Song of Ice and Fire. Winter is coming to the Seven Kingdoms."
)
book3.authors << author2
book3.categories << [ fiction, fantasy, adventure ]
book3.tags << [ bestseller, award_winner, recommended ]

book4 = Book.create!(
  title: "Murder on the Orient Express",
  isbn: "9780062693662",
  publication_year: 1934,
  total_copies: 4,
  available_copies: 4,
  description: "Just after midnight, a snowdrift stops the Orient Express in its tracks. The luxurious train is surprisingly full, but by morning one passenger is dead."
)
book4.authors << author3
book4.categories << [ fiction, mystery, classic ]
book4.tags << [ classic_tag, recommended ]

book5 = Book.create!(
  title: "And Then There Were None",
  isbn: "9780062073488",
  publication_year: 1939,
  total_copies: 4,
  available_copies: 0,
  description: "Ten strangers are lured to an isolated island mansion off the Devon coast. One by one, they are murdered according to a nursery rhyme."
)
book5.authors << author3
book5.categories << [ fiction, mystery, thriller ]
book5.tags << [ classic_tag, bestseller ]

book6 = Book.create!(
  title: "Foundation",
  isbn: "9780553293357",
  publication_year: 1951,
  total_copies: 5,
  available_copies: 5,
  description: "The first novel in Isaac Asimov's classic science-fiction masterpiece, the Foundation series."
)
book6.authors << author4
book6.categories << [ fiction, scifi ]
book6.tags << [ classic_tag, award_winner ]

book7 = Book.create!(
  title: "Pride and Prejudice",
  isbn: "9780141439518",
  publication_year: 1813,
  total_copies: 7,
  available_copies: 4,
  description: "A romantic novel of manners that follows the character development of Elizabeth Bennet, the protagonist."
)
book7.authors << author5
book7.categories << [ fiction, romance, classic ]
book7.tags << [ classic_tag, recommended, popular ]

book8 = Book.create!(
  title: "The Shining",
  isbn: "9780307743657",
  publication_year: 1977,
  total_copies: 4,
  available_copies: 3,
  description: "Jack Torrance's new job at the Overlook Hotel is the perfect chance for a fresh start. But the hotel has a dark history."
)
book8.authors << author6
book8.categories << [ fiction, horror, thriller ]
book8.tags << [ bestseller, popular ]

book9 = Book.create!(
  title: "The Handmaid's Tale",
  isbn: "9780385490818",
  publication_year: 1985,
  total_copies: 6,
  available_copies: 3,
  description: "Offred is a Handmaid in the Republic of Gilead. She may leave the home of the Commander once a day to walk to food markets."
)
book9.authors << author7
book9.categories << [ fiction, scifi, classic ]
book9.tags << [ award_winner, bestseller, recommended ]

book10 = Book.create!(
  title: "The Old Man and the Sea",
  isbn: "9780684801223",
  publication_year: 1952,
  total_copies: 5,
  available_copies: 5,
  description: "The story of Santiago, an aging Cuban fisherman who struggles with a giant marlin far out in the Gulf Stream."
)
book10.authors << author8
book10.categories << [ fiction, classic, adventure ]
book10.tags << [ classic_tag, award_winner ]

book11 = Book.create!(
  title: "Beloved",
  isbn: "9781400033416",
  publication_year: 1987,
  total_copies: 4,
  available_copies: 4,
  description: "Sethe, a former slave, lives in Ohio after the Civil War. She is haunted by the ghost of her dead daughter."
)
book11.authors << author9
book11.categories << [ fiction, history, classic ]
book11.tags << [ award_winner, classic_tag ]

book12 = Book.create!(
  title: "One Hundred Years of Solitude",
  isbn: "9780060883287",
  publication_year: 1967,
  total_copies: 5,
  available_copies: 2,
  description: "The story of the Buendía family over seven generations in the fictional town of Macondo."
)
book12.authors << author10
book12.categories << [ fiction, classic ]
book12.tags << [ classic_tag, award_winner, recommended ]

book13 = Book.create!(
  title: "It",
  isbn: "9781501142970",
  publication_year: 1986,
  total_copies: 6,
  available_copies: 1,
  description: "Welcome to Derry, Maine. It's a small city, a place as hauntingly familiar as your own hometown."
)
book13.authors << author6
book13.categories << [ fiction, horror ]
book13.tags << [ bestseller, popular ]

book14 = Book.create!(
  title: "Sense and Sensibility",
  isbn: "9780141439662",
  publication_year: 1811,
  total_copies: 4,
  available_copies: 3,
  description: "The story of the Dashwood sisters, who must find new housing and new husbands after their father's death."
)
book14.authors << author5
book14.categories << [ fiction, romance, classic ]
book14.tags << [ classic_tag ]

book15 = Book.create!(
  title: "A Clash of Kings",
  isbn: "9780553108033",
  publication_year: 1998,
  total_copies: 4,
  available_copies: 0,
  description: "The second book in A Song of Ice and Fire. The war continues as five kings claim the Iron Throne."
)
book15.authors << author2
book15.categories << [ fiction, fantasy ]
book15.tags << [ bestseller, popular ]

puts "✅ Created #{Book.count} books"

# Create Borrowings
puts "\n📋 Creating borrowings..."

# Returned borrowings first
Borrowing.create!(
  user: member1,
  book: book4,
  borrowed_date: Date.today - 40.days,
  due_date: Date.today - 26.days,
  returned_date: Date.today - 28.days,
  status: 'returned'
)

Borrowing.create!(
  user: member2,
  book: book6,
  borrowed_date: Date.today - 35.days,
  due_date: Date.today - 21.days,
  returned_date: Date.today - 20.days,
  status: 'returned'
)

Borrowing.create!(
  user: member3,
  book: book10,
  borrowed_date: Date.today - 50.days,
  due_date: Date.today - 36.days,
  returned_date: Date.today - 34.days,
  status: 'returned'
)

# Active borrowings for users without overdue books
Borrowing.create!(
  user: member1,
  book: book1,
  borrowed_date: Date.today - 5.days,
  due_date: Date.today + 9.days,
  status: 'active'
)

Borrowing.create!(
  user: member1,
  book: book3,
  borrowed_date: Date.today - 3.days,
  due_date: Date.today + 11.days,
  status: 'active'
)

Borrowing.create!(
  user: member4,
  book: book8,
  borrowed_date: Date.today - 1.day,
  due_date: Date.today + 13.days,
  status: 'active'
)

# Overdue borrowings (bypass validation)
Borrowing.new(
  user: member2,
  book: book12,
  borrowed_date: Date.today - 25.days,
  due_date: Date.today - 11.days,
  status: 'overdue'
).save!(validate: false)

Borrowing.new(
  user: member3,
  book: book13,
  borrowed_date: Date.today - 30.days,
  due_date: Date.today - 16.days,
  status: 'overdue'
).save!(validate: false)

puts "✅ Created #{Borrowing.count} borrowings (#{Borrowing.active.count} active, #{Borrowing.overdue.count} overdue, #{Borrowing.returned.count} returned)"

# Create Reservations
puts "\n🔖 Creating reservations..."

Reservation.create!(
  user: member1,
  book: book5,
  reservation_date: Date.today - 3.days,
  status: 'pending'
)

Reservation.create!(
  user: member2,
  book: book5,
  reservation_date: Date.today - 1.day,
  status: 'pending'
)

Reservation.create!(
  user: member4,
  book: book15,
  reservation_date: Date.today - 2.days,
  status: 'pending'
)

Reservation.create!(
  user: member3,
  book: book15,
  reservation_date: Date.today,
  status: 'pending'
)

puts "✅ Created #{Reservation.count} reservations"

# Create Reviews
puts "\n⭐ Creating reviews..."

# Book reviews
Review.create!(
  user: member1,
  reviewable: book1,
  rating: 5,
  comment: "Absolutely magical! This book started my love for the Harry Potter series. The world-building is incredible and the characters are so well-developed.",
  status: 'approved'
)

Review.create!(
  user: member2,
  reviewable: book1,
  rating: 5,
  comment: "A timeless classic that appeals to both children and adults. J.K. Rowling's imagination knows no bounds!",
  status: 'approved'
)

Review.create!(
  user: member3,
  reviewable: book1,
  rating: 4,
  comment: "Great introduction to the wizarding world. Highly recommended for fantasy lovers.",
  status: 'approved'
)

Review.create!(
  user: member1,
  reviewable: book3,
  rating: 5,
  comment: "George R.R. Martin weaves an incredibly complex and engaging story. The characters are morally grey and realistic.",
  status: 'approved'
)

Review.create!(
  user: member4,
  reviewable: book3,
  rating: 4,
  comment: "Epic fantasy at its finest. Be prepared for a long journey with multiple perspectives.",
  status: 'approved'
)

Review.create!(
  user: member2,
  reviewable: book7,
  rating: 5,
  comment: "Jane Austen's wit and social commentary are timeless. Elizabeth Bennet is one of literature's greatest heroines.",
  status: 'approved'
)

Review.create!(
  user: member3,
  reviewable: book9,
  rating: 5,
  comment: "A haunting and powerful dystopian novel that feels more relevant than ever.",
  status: 'approved'
)

Review.create!(
  user: member1,
  reviewable: book4,
  rating: 5,
  comment: "Agatha Christie at her best! The twist ending is absolutely brilliant.",
  status: 'approved'
)

Review.create!(
  user: member4,
  reviewable: book8,
  rating: 5,
  comment: "Genuinely terrifying! Stephen King's mastery of psychological horror is on full display.",
  status: 'approved'
)

Review.create!(
  user: member2,
  reviewable: book12,
  rating: 5,
  comment: "A masterpiece of magical realism. García Márquez's prose is beautiful and dreamlike.",
  status: 'approved'
)

# Author reviews
Review.create!(
  user: member1,
  reviewable: author1,
  rating: 5,
  comment: "J.K. Rowling created a world that has touched millions of hearts. An incredible storyteller!",
  status: 'approved'
)

Review.create!(
  user: member2,
  reviewable: author3,
  rating: 5,
  comment: "The Queen of Mystery! No one writes detective fiction like Agatha Christie.",
  status: 'approved'
)

Review.create!(
  user: member3,
  reviewable: author6,
  rating: 5,
  comment: "Stephen King is the master of horror. His ability to create atmosphere is unmatched.",
  status: 'approved'
)

# Pending review (for testing approval)
Review.create!(
  user: member4,
  reviewable: book6,
  rating: 4,
  comment: "Great science fiction foundation. Asimov's ideas are ahead of his time.",
  status: 'pending'
)

puts "✅ Created #{Review.count} reviews (#{Review.approved.count} approved, #{Review.pending.count} pending)"

# Update book ratings
puts "\n📊 Updating book ratings..."
Book.find_each(&:update_average_rating!)
puts "✅ Book ratings updated"

# Update Profiles
puts "\n👤 Creating user profiles..."

member1.profile.update(
  bio: "Avid reader and fantasy enthusiast. Love getting lost in magical worlds!",
  birth_date: Date.new(1990, 5, 15),
  liked_genres: [ "Fiction", "Fantasy", "Young Adult" ],
  favorite_author: author1
)

member2.profile.update(
  bio: "Classic literature lover. Jane Austen and Agatha Christie are my favorites.",
  birth_date: Date.new(1985, 8, 22),
  liked_genres: [ "Classic", "Mystery", "Romance" ],
  favorite_author: author5
)

member3.profile.update(
  bio: "Horror and thriller fan. Stephen King keeps me up at night!",
  birth_date: Date.new(1992, 11, 3),
  liked_genres: [ "Horror", "Thriller", "Mystery" ],
  favorite_author: author6
)

member4.profile.update(
  bio: "Sci-fi and dystopian fiction reader. Always looking for thought-provoking books.",
  birth_date: Date.new(1988, 3, 30),
  liked_genres: [ "Science Fiction", "Fiction" ],
  favorite_author: author7
)

librarian.profile.update(
  bio: "Library administrator with a passion for connecting readers with great books.",
  birth_date: Date.new(1980, 1, 10),
  liked_genres: [ "Biography", "History", "Non-Fiction" ],
  favorite_author: author8
)

puts "✅ User profiles updated"

# Print Summary
puts "\n" + "="*50
puts "🎉 SEED DATA COMPLETED SUCCESSFULLY!"
puts "="*50

puts "\n📊 DATABASE SUMMARY:"
puts "-" * 50
puts "👥 Users:          #{User.count} (#{User.librarian.count} librarians, #{User.member.count} members)"
puts "📚 Categories:     #{Category.count}"
puts "🏷️  Tags:          #{Tag.count}"
puts "✍️  Authors:        #{Author.count}"
puts "📖 Books:          #{Book.count}"
puts "📋 Borrowings:     #{Borrowing.count}"
puts "   - Active:       #{Borrowing.active.count}"
puts "   - Overdue:      #{Borrowing.overdue.count}"
puts "   - Returned:     #{Borrowing.returned.count}"
puts "🔖 Reservations:   #{Reservation.count}"
puts "⭐ Reviews:        #{Review.count}"
puts "   - Approved:     #{Review.approved.count}"
puts "   - Pending:      #{Review.pending.count}"
puts "-" * 50

puts "\n🔐 TEST ACCOUNTS:"
puts "-" * 50
puts "Librarian: admin@library.com / password123"
puts "Member 1:  john@example.com / password123"
puts "Member 2:  jane@example.com / password123"
puts "Member 3:  bob@example.com / password123"
puts "Member 4:  alice@example.com / password123"
puts "-" * 50

puts "\n📚 POPULAR BOOKS:"
puts "-" * 50
Book.order(reviews_count: :desc).limit(5).each_with_index do |book, index|
  puts "#{index + 1}. #{book.title} (#{book.reviews_count} reviews, #{book.average_rating&.round(1)}/5 ⭐)"
end
puts "-" * 50
