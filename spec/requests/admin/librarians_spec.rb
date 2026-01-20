require 'rails_helper'

RSpec.describe "Admin::Librarians", type: :request do
  let(:admin_user) { create(:admin_user) }
  let!(:librarian_resource) { create(:librarian, name: "Target Librarian") }
  

  let(:member) { create(:member, name: "Borrowing Member") }
  let(:book) { create(:book, title: "Library Book", total_copies: 50, available_copies: 50) }
  

  let!(:borrowing_ok) do
    create(:borrowing, 
      librarian: librarian_resource, 
      member: member, 
      book: book, 
      status: :returned,
      borrowed_date: 2.weeks.ago,
      returned_date: 1.week.ago
    ) 
  end
  

  let!(:borrowing_overdue) do
    create(:borrowing, 
      librarian: librarian_resource, 
      member: member, 
      book: book, 
      status: :overdue, 
      borrowed_date: 1.month.ago,
      due_date: 1.week.ago
    ) 
  end

  before do
    sign_in admin_user
  end

  describe "GET /admin/librarians (Index)" do
    it "renders the index page with custom columns" do
      get admin_librarians_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Target Librarian")
      expect(response.body).to include("2") # Borrowings count
    end
  end

  describe "GET /admin/librarians/:id (Show)" do
    it "renders the details and the borrowings panel with correct formatting" do
      get admin_librarian_path(librarian_resource)
      expect(response).to have_http_status(:success)
      
     
      expect(response.body).to include("Target Librarian")
      expect(response.body).to include(librarian_resource.email)
      
     
      expect(response.body).to include("Recent Borrowings Processed (2)")
      
     
      expect(response.body).to include("Borrowing Member")
      expect(response.body).to include("Library Book")
      
      
      expect(response.body).to include('status_tag returned ok')
      expect(response.body).to include('status_tag overdue error')
    end
  end

  describe "GET /admin/librarians/new (Form)" do
    it "renders the new form inputs" do
      get new_admin_librarian_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Librarian Details")
      expect(response.body).to include("Password")
    end
  end

  describe "POST /admin/librarians (Create)" do
    let(:valid_params) do
      {
        librarian: {
          name: "New Lib",
          email: "newlib@example.com",
          phone: "1234567890",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    it "creates a new librarian" do
      expect {
        post admin_librarians_path, params: valid_params
      }.to change(Librarian, :count).by(1)
      
      expect(response).to redirect_to(admin_librarian_path(Librarian.last))
    end
  end

  describe "GET /admin/librarians/:id/edit" do
    it "renders the edit form" do
      get edit_admin_librarian_path(librarian_resource)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT /admin/librarians/:id (Update)" do
    let(:update_params) { { librarian: { name: "Updated Name" } } }

    it "updates the librarian" do
      put admin_librarian_path(librarian_resource), params: update_params
      expect(response).to redirect_to(admin_librarian_path(librarian_resource))
      expect(librarian_resource.reload.name).to eq("Updated Name")
    end
  end
  
  describe "Filtering" do
    before do
      allow(Librarian).to receive(:ransackable_attributes).and_return(["name", "email", "created_at", "id", "updated_at", "phone"])
    end

    it "filters by name" do
      # Use 'name_cont' (contains) which is the standard Ransack predicate
      get admin_librarians_path(q: { name_cont: "Target" })
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Target Librarian")
    end
  end
end