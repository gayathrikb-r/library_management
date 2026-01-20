require 'rails_helper'

RSpec.describe "Admin::Authors", type: :request do
  let(:admin_user) { create(:admin_user) }
  

  let!(:author) { create(:author, name: "Test Author", birth_date: 30.years.ago, biography: "Bio") }

  let!(:book) { create(:book, title: "Author's Masterpiece", authors: [author]) }

  before do
    sign_in admin_user
    

    allow(Author).to receive(:ransackable_attributes).and_return(["name", "birth_date", "created_at", "id", "updated_at"])
    allow(Author).to receive(:ransackable_associations).and_return(["books", "reviews"])
  end

  describe "GET /admin/authors (Index)" do
    it "renders the index page with books count" do
      get admin_authors_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Test Author")
   
      expect(response.body).to include("1") 
    end

    it "filters by name" do
      get admin_authors_path(q: { name_cont: "Test" })
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Test Author")
    end
  end

  describe "GET /admin/authors/:id (Show)" do
    it "renders the author details, calculated age, and books panel" do
      get admin_author_path(author)
      expect(response).to have_http_status(:success)
      

      expect(response.body).to include("Test Author")
      expect(response.body).to include("Bio")
      

      expect(response.body).to include("30")
      
    
      expect(response.body).to include("Books by this Author (1)")
      expect(response.body).to include("Author&#39;s Masterpiece") # &#39; is HTML encoded apostrophe
    end

    it "handles N/A age when birth_date is missing" do
      author_no_bday = create(:author, name: "Unknown Age", birth_date: nil)
      get admin_author_path(author_no_bday)
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("N/A")
    end
  end

  describe "GET /admin/authors/new" do
    it "renders the new form" do
      get new_admin_author_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Biography") # Verifies text input
    end
  end

  describe "POST /admin/authors (Create)" do
    let(:valid_params) do
      {
        author: {
          name: "New Author",
          biography: "New Bio",
          birth_date: "1990-01-01"
        }
      }
    end

    it "creates a new author" do
      expect {
        post admin_authors_path, params: valid_params
      }.to change(Author, :count).by(1)
      
      expect(response).to redirect_to(admin_author_path(Author.last))
    end
  end

  describe "GET /admin/authors/:id/edit" do
    it "renders the edit form" do
      get edit_admin_author_path(author)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT /admin/authors/:id (Update)" do
    let(:update_params) { { author: { name: "Updated Name" } } }

    it "updates the author" do
      put admin_author_path(author), params: update_params
      expect(response).to redirect_to(admin_author_path(author))
      expect(author.reload.name).to eq("Updated Name")
    end
  end
end