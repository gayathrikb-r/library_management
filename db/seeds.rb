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
# Clear existing data (be careful in production!)
# Clear existing data (be careful in production!)
puts "🗑️  Cleaning database..."
Review.destroy_all
Borrowing.destroy_all
Reservation.destroy_all
BookAuthor.destroy_all
BookCategory.destroy_all
MemberCategory.destroy_all
Book.delete_all
Author.delete_all
Category.delete_all
Tag.delete_all
Member.delete_all
Librarian.delete_all
AdminUser.delete_all

puts "✅ Database cleaned!"

# Create Admin User
puts "\n👤 Creating Admin User..."
AdminUser.create!(
  email: 'admin@library.com',
  password: 'password123',
  password_confirmation: 'password123'
)
puts "✅ Admin created: admin@library.com / password123"

# Create Librarians
puts "\n📚 Creating Librarians..."
librarian1 = Librarian.create!(
  name: 'Sarah Johnson',
  email: 'sarah@library.com',
  phone: '9876543210',  # 10 digit phone number
  password: 'password123',
  password_confirmation: 'password123'
)

librarian2 = Librarian.create!(
  name: 'Michael Chen',
  email: 'michael@library.com',
  phone: '9876543211',  # 10 digit phone number
  password: 'password123',
  password_confirmation: 'password123'
)
puts "✅ 2 Librarians created"

# Create Categories
puts "\n📂 Creating Categories..."
categories = [
  'Fiction',
  'Non-Fiction',
  'Science Fiction',
  'Mystery',
  'Romance',
  'Biography',
  'History',
  'Science',
  'Technology',
  'Self-Help'
].map { |name| Category.create!(name: name) }
puts "✅ #{categories.count} Categories created"

# Create Tags
puts "\n🏷️  Creating Tags..."
tags = [
  'Bestseller',
  'Award Winner',
  'Classic',
  'New Release',
  'Popular'
].map { |name| Tag.create!(name: name) }
puts "✅ #{tags.count} Tags created"

# Create Authors
puts "\n✍️  Creating Authors..."
authors = [
  { name: 'J.K. Rowling', biography: 'British author best known for the Harry Potter series', birth_date: '1965-07-31' },
  { name: 'George Orwell', biography: 'English novelist and essayist', birth_date: '1903-06-25' },
  { name: 'Jane Austen', biography: 'English novelist known for romantic fiction', birth_date: '1775-12-16' },
  { name: 'Stephen King', biography: 'American author of horror and suspense novels', birth_date: '1947-09-21' },
  { name: 'Agatha Christie', biography: 'English writer known for detective novels', birth_date: '1890-09-15' },
  { name: 'Isaac Asimov', biography: 'American writer and professor of biochemistry', birth_date: '1920-01-02' },
  { name: 'Maya Angelou', biography: 'American memoirist, poet, and civil rights activist', birth_date: '1928-04-04' },
  { name: 'Malcolm Gladwell', biography: 'Canadian journalist and author', birth_date: '1963-09-03' }
].map { |attrs| Author.create!(attrs) }
puts "✅ #{authors.count} Authors created"

# Create Members
puts "\n👥 Creating Members..."
10.times do |i|
  Member.create!(
    name: "Member #{i+1}",
    email: "member#{i+1}@example.com",
    phone: "98765432#{10+i}",  # 10 digit phone numbers
    bio: "I love reading books and exploring new genres.",
    birth_date: Date.today - rand(18..80).years,
    favorite_author: authors.sample,
    password: 'password123',
    password_confirmation: 'password123'
  )
end
members = Member.all
puts "✅ #{members.count} Members created"

# Create Books
puts "\n📖 Creating Books..."
books_data = [
  { title: "Harry Potter and the Philosopher's Stone", isbn: '9780439708180', year: 1997, copies: 5, author: authors[0], categories: [categories[0], categories[2]], description: "A young wizard discovers his magical heritage on his eleventh birthday." },
  { title: "1984", isbn: '9780451524935', year: 1949, copies: 4, author: authors[1], categories: [categories[0], categories[2]], description: "A dystopian social science fiction novel and cautionary tale." },
  { title: "Pride and Prejudice", isbn: '9780141439518', year: 1813, copies: 3, author: authors[2], categories: [categories[0], categories[4]], description: "A romantic novel of manners set in Georgian England." },
  { title: "The Shining", isbn: '9780385121675', year: 1977, copies: 4, author: authors[3], categories: [categories[0], categories[3]], description: "A horror novel about a family isolated in a haunted hotel." },
  { title: "Murder on the Orient Express", isbn: '9780062693662', year: 1934, copies: 3, author: authors[4], categories: [categories[0], categories[3]], description: "A detective novel featuring the famous Hercule Poirot." },
  { title: "Foundation", isbn: '9780553293357', year: 1951, copies: 3, author: authors[5], categories: [categories[2], categories[7]], description: "A science fiction novel about the fall and rise of galactic empires." },
  { title: "I Know Why the Caged Bird Sings", isbn: '9780345514400', year: 1969, copies: 2, author: authors[6], categories: [categories[5], categories[1]], description: "An autobiography describing the early years of American writer and poet." },
  { title: "Outliers", isbn: '9780316017930', year: 2008, copies: 4, author: authors[7], categories: [categories[1], categories[9]], description: "An examination of the factors that contribute to high levels of success." },
  { title: "The Stand", isbn: '9780307743688', year: 1978, copies: 3, author: authors[3], categories: [categories[0], categories[6]], description: "A post-apocalyptic horror/fantasy novel about the survivors of a plague." },
  { title: "Emma", isbn: '9780141439587', year: 1815, copies: 2, author: authors[2], categories: [categories[0], categories[4]], description: "A novel about youthful hubris and romantic misunderstandings." }
]

books_data.each do |book_data|
  book = Book.create!(
    title: book_data[:title],
    isbn: book_data[:isbn],
    publication_year: book_data[:year],
    total_copies: book_data[:copies],
    available_copies: book_data[:copies],
    description: book_data[:description]
  )
  
  # Add author
  BookAuthor.create!(book: book, author: book_data[:author])
  
  # Add categories
  book_data[:categories].each do |category|
    BookCategory.create!(book: book, category: category)
  end
  
  # Add random tags
  book.tags << tags.sample(rand(1..3))
end

books = Book.all
puts "✅ #{books.count} Books created"
puts "\n📚 Creating Borrowings..."

# -------------------------------
# 1️⃣ Overdue borrowings
# -------------------------------
3.times do
  book = books.sample
  next if book.total_copies <= 0 # just to avoid negative numbers

  Borrowing.new(
    member: members.sample,
    book: book,
    librarian: [librarian1, librarian2].sample,
    borrowed_date: rand(25..40).days.ago.to_date,
    due_date: rand(10..15).days.ago.to_date,
    status: :overdue
  ).save!(validate: false)  # skip validations
  book.decrement!(:available_copies)
end

# -------------------------------
# 2️⃣ Returned borrowings
# -------------------------------
7.times do
  book = books.sample
  Borrowing.new(
    member: members.sample,
    book: book,
    librarian: [librarian1, librarian2].sample,
    borrowed_date: rand(30..60).days.ago.to_date,
    due_date: rand(15..25).days.ago.to_date,
    returned_date: rand(1..10).days.ago.to_date,
    status: :returned
  ).save!(validate: false)
end

# -------------------------------
# 3️⃣ Active borrowings
# -------------------------------
5.times do
  book = books.sample
  next if book.available_copies <= 0

  Borrowing.create!(
    member: members.sample,
    book: book,
    librarian: [librarian1, librarian2].sample,
    borrowed_date: rand(1..20).days.ago.to_date,
    due_date: rand(1..10).days.from_now.to_date,
    status: :borrowed
  )
  book.decrement!(:available_copies)
end

puts "✅ #{Borrowing.count} Borrowings created"

# Create Reservations
puts "\n📋 Creating Reservations..."

# -------------------------------
# Pending reservations
# -------------------------------
4.times do
  book = books.sample
  next if book.total_copies <= 0

  Reservation.new(
    member: members.sample,
    book: book,
    reservation_date: Date.today,
    expires_at: 7.days.from_now,
    status: :pending
  ).save!(validate: false) # skip validations
end

# -------------------------------
# Fulfilled reservations
# -------------------------------
2.times do
  book = books.sample
  Reservation.new(
    member: members.sample,
    book: book,
    reservation_date: 5.days.ago.to_date,
    notified_at: 3.days.ago,
    expires_at: 4.days.from_now,
    status: :fulfilled
  ).save!(validate: false) # skip validations
end


puts "✅ #{Reservation.count} Reservations created"

# Create Reviews
puts "\n⭐ Creating Reviews..."

# Approved reviews
books.sample(8).each do |book|
  Review.create!(
    reviewer: members.sample,
    reviewable: book,
    rating: rand(3..5),
    comment: "This book was #{['amazing', 'fantastic', 'great', 'wonderful', 'excellent'].sample}! I really enjoyed reading it and would recommend it to others.",
    status: :approved
  )
end

# Pending reviews
books.sample(3).each do |book|
  Review.create!(
    reviewer: members.sample,
    reviewable: book,
    rating: rand(3..5),
    comment: "A #{['good', 'solid', 'decent', 'interesting'].sample} read. I found it engaging and worth my time.",
    status: :pending
  )
end

puts "✅ #{Review.count} Reviews created"

# Update book ratings
Book.find_each do |book|
  approved_reviews = book.reviews.approved
  if approved_reviews.any?
    book.update!(
      average_rating: approved_reviews.average(:rating).round(2),
      reviews_count: approved_reviews.count
    )
  end
end

puts "\n" + "="*50
puts "🎉 SEED COMPLETED!"
puts "="*50
puts "\n📊 Summary:"
puts "  • Admin Users: #{AdminUser.count}"
puts "  • Librarians: #{Librarian.count}"
puts "  • Members: #{Member.count}"
puts "  • Authors: #{Author.count}"
puts "  • Categories: #{Category.count}"
puts "  • Tags: #{Tag.count}"
puts "  • Books: #{Book.count}"
puts "  • Borrowings: #{Borrowing.count}"
puts "  • Reservations: #{Reservation.count}"
puts "  • Reviews: #{Review.count}"
puts "\n🔑 Login Credentials:"
puts "  Admin:     admin@library.com / password123"
puts "  Librarian: sarah@library.com / password123"
puts "  Librarian: michael@library.com / password123"
puts "  Members:   member1@example.com (through member10@example.com) / password123"
puts "\n✅ All set! Start your Rails server and log in!"
puts "="*50