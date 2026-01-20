require 'rails_helper'

RSpec.describe "Admin::Books", type: :request do
  
  let(:admin_user) { create(:admin_user) }
  

  let(:author) { create(:author, name: "J.K. Rowling") }
  let(:category) { create(:category, name: "Fantasy") }
  let(:tag) { create(:tag, name: "Bestseller") } 
  let(:member) { create(:member, name: "John Doe") }


  let!(:book) do 
    create(:book, 
      title: "Harry Potter", 
      authors: [author], 
      categories: [category], 
      tags: [tag]
    ) 
  end

  let!(:borrowing) { create(:borrowing, book: book, member: member) }
  
  let!(:review) { create(:review, reviewable: book, reviewer: member, rating: 5, comment: "This is an amazing book!") }

  before do
    sign_in admin_user
  end

  describe "GET /admin/books (Index)" do
    it "renders the index page and displays associated data" do
      get admin_books_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Harry Potter")
      expect(response.body).to include("J.K. Rowling") # column("Authors")
    end
  end

  describe "GET /admin/books/:id (Show)" do
    it "renders the show page with Attributes, History, and Reviews panels" do
      get admin_book_path(book)
      
      expect(response).to have_http_status(:success)

      expect(response.body).to include("Harry Potter")
      expect(response.body).to include("J.K. Rowling") # row("Authors")
      expect(response.body).to include("Fantasy")      # row("Categories")
      expect(response.body).to include("Bestseller")   # row("Tags")
      

      expect(response.body).to include("Borrowing History")
      expect(response.body).to include("John Doe")     # column "Member" link
      

      expect(response.body).to include("Reviews")
      expect(response.body).to include("This is an amazing book!") # column :comment
      expect(response.body).to include("John Doe")     # column("Reviewer") link
    end
  end

  describe "GET /admin/books/new" do
    it "renders the new book form" do
      get new_admin_book_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("input")
      expect(response.body).to include("author_ids")
    end
  end

  describe "POST /admin/books" do
    let(:valid_params) do
      {
        book: {
          title: "New Admin Book",
          isbn: "9876543210",
          total_copies: 5,
          available_copies: 5,
          description: "Created via Admin",
          author_ids: [author.id],
          category_ids: [category.id]
        }
      }
    end

    it "creates a book successfully" do
      expect {
        post admin_books_path, params: valid_params
      }.to change(Book, :count).by(1)

      expect(response).to redirect_to(admin_book_path(Book.last))
    end
  end

  describe "GET /admin/books/:id/edit" do
    it "renders the edit form" do
      get edit_admin_book_path(book)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Harry Potter")
    end
  end

  describe "PUT /admin/books/:id" do
    let(:update_params) { { book: { title: "Updated Admin Title" } } }

    it "updates the book successfully" do
      put admin_book_path(book), params: update_params
      
      expect(response).to redirect_to(admin_book_path(book))
      expect(book.reload.title).to eq("Updated Admin Title")
    end
  end

  describe "Filtering" do
    it "allows filtering by title" do
      get admin_books_path(q: { title_contains: "Harry" })
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Harry Potter")
    end
  end
end