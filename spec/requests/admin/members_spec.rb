require 'rails_helper'

RSpec.describe "Admin::Members", type: :request do
  let(:admin_user) { create(:admin_user) }
  

  let(:author) { create(:author, name: "J.K. Rowling") }
  let(:category) { create(:category, name: "Fantasy") }
  let(:book) { create(:book, title: "Harry Potter", authors: [author]) }


  let!(:member) do
    create(:member, 
      name: "Alice Wonderland", 
      email: "alice@example.com",
      favorite_author: author,
      liked_categories: [category]
    )
  end


  let!(:borrowing) { create(:borrowing, member: member, book: book, status: :borrowed) }
  let!(:reservation) { create(:reservation, member: member, book: book) }

  before do
    sign_in admin_user
  end

  describe "GET /admin/members (Index)" do
    it "renders the index page with scoped collection and custom columns" do
      get admin_members_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Alice Wonderland")
      

      expect(response.body).to include("1") 
    end

    it "allows filtering by name" do
      get admin_members_path(q: { name_contains: "Alice" })
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Alice Wonderland")
    end
  end

  describe "GET /admin/members/:id (Show)" do
    it "renders the show page with attributes and panels" do
      get admin_member_path(member)
      
      expect(response).to have_http_status(:success)
      

      expect(response.body).to include("Alice Wonderland")
      expect(response.body).to include("J.K. Rowling")
      expect(response.body).to include("Fantasy")     
      
     
      expect(response.body).to include("Current Borrowings")
      expect(response.body).to include("Harry Potter")
      
    
      expect(response.body).to include("Reservations")
    
      expect(response.body).to include("/admin/books/#{book.id}")
    end
  end

  describe "GET /admin/members/new" do
    it "renders the new member form" do
      get new_admin_member_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Member Details")
      expect(response.body).to include("favorite_author_id")
      expect(response.body).to include("liked_category_ids")
    end
  end

  describe "POST /admin/members" do
    let(:valid_params) do
      {
        member: {
          name: "New Member",
          email: "new@example.com",
          password: "password",
          password_confirmation: "password",
          phone: "1234567890",
          bio: "New Bio",
          birth_date: "1990-01-01",
          favorite_author_id: author.id,
          liked_category_ids: [category.id]
        }
      }
    end

    it "creates a member successfully" do
      expect {
        post admin_members_path, params: valid_params
      }.to change(Member, :count).by(1)

      member = Member.last
      expect(response).to redirect_to(admin_member_path(member))
      expect(member.liked_categories).to include(category)
      expect(member.favorite_author).to eq(author)
    end
  end

  describe "GET /admin/members/:id/edit" do
    it "renders the edit form" do
      get edit_admin_member_path(member)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Alice Wonderland")
    end
  end

  describe "PUT /admin/members/:id" do
    let(:update_params) do 
      { 
        member: { 
          name: "Updated Alice",
          liked_category_ids: [] 
        } 
      } 
    end

    it "updates the member successfully" do
      put admin_member_path(member), params: update_params
      
      expect(response).to redirect_to(admin_member_path(member))
      expect(member.reload.name).to eq("Updated Alice")
      expect(member.liked_categories).to be_empty
    end
  end
end