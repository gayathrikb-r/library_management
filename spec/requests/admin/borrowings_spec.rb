require 'rails_helper'

RSpec.describe "Admin::Borrowings", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:librarian) { create(:librarian, name: "Mr. Librarian") }

  let(:member_alice) { create(:member, name: "Alice") }
  let(:member_bob) { create(:member, name: "Bob") }
  let(:member_charlie) { create(:member, name: "Charlie") }

  let(:book_active) { create(:book, title: "The Hobbit", total_copies: 50, available_copies: 50) }
  let(:book_overdue) { create(:book, title: "Lord of the Rings", total_copies: 50, available_copies: 50) }
  let(:book_returned) { create(:book, title: "Silmarillion", total_copies: 50, available_copies: 50) }

  let!(:active_borrowing) do
    create(:borrowing, 
      member: member_alice, 
      book: book_active, 
      status: :borrowed, 
      borrowed_date: Date.today, 
      due_date: 1.week.from_now
    )
  end

  let!(:overdue_borrowing) do
    create(:borrowing, 
      member: member_bob, 
      book: book_overdue, 
      status: :borrowed, 
      borrowed_date: 1.month.ago, 
      due_date: 1.week.ago
    )
  end

  let!(:returned_borrowing) do
    create(:borrowing, 
      member: member_charlie, 
      book: book_returned, 
      status: :returned, 
      borrowed_date: 1.month.ago, 
      due_date: 1.week.ago,
      returned_date: Date.today
    )
  end

  before do
    sign_in admin_user
  end

  describe "GET /admin/borrowings (Index)" do
    it "renders the index page" do
      get admin_borrowings_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Alice")
      expect(response.body).to include("The Hobbit")
    end

    it "filters by 'borrowed' scope" do
      get admin_borrowings_path(scope: 'borrowed')
      expect(response).to have_http_status(:success)
      expect(response.body).to include(active_borrowing.book.title)
    end

    it "filters by 'returned' scope" do
      get admin_borrowings_path(scope: 'returned')
      expect(response).to have_http_status(:success)
      expect(response.body).to include(returned_borrowing.book.title)
    end

    it "filters by 'overdue' scope" do
      get admin_borrowings_path(scope: 'overdue')
      expect(response).to have_http_status(:success)
      expect(response.body).to include(overdue_borrowing.book.title)
    end

    it "renders the status tags correctly" do
      get admin_borrowings_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('status_tag no ok')   # For "No" (Not Overdue)
      expect(response.body).to include('status_tag yes error') # For "Yes" (Overdue)
    end
  end

  describe "POST /admin/borrowings (Create)" do
    let(:new_book) { create(:book, title: "New Adventure", total_copies: 10, available_copies: 10) }
    
    let(:valid_params) do
      {
        borrowing: {
          member_id: member_alice.id,
          book_id: new_book.id,
          borrowed_date: Date.today,
          due_date: 2.weeks.from_now,
          status: 'borrowed'
        }
      }
    end

    it "creates a borrowing" do
      expect {
        post admin_borrowings_path, params: valid_params
      }.to change(Borrowing, :count).by(1)
      expect(response).to redirect_to(admin_borrowing_path(Borrowing.last))
    end
  end

  describe "GET /admin/borrowings/:id (Show)" do
    it "renders the show page and action item" do
      get admin_borrowing_path(active_borrowing)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Mark as Returned")
    end
  end

  describe "PUT /admin/borrowings/:id/return_book" do
    it "returns the book" do
      initial_copies = book_active.reload.available_copies
      put return_book_admin_borrowing_path(active_borrowing)
      
      expect(response).to redirect_to(admin_borrowing_path(active_borrowing))
      expect(flash[:notice]).to eq("Book returned successfully!")
      expect(active_borrowing.reload.status).to eq("returned")
      expect(book_active.reload.available_copies).to eq(initial_copies + 1)
    end
  end

  describe "Filtering" do
    it "filters by member" do
      get admin_borrowings_path(q: { member_id_eq: member_alice.id })
      expect(response).to have_http_status(:success)
      expect(response.body).to include(member_alice.name)
    end
  end
end