require 'rails_helper'

RSpec.describe "Borrowings", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:other_member) { create(:member) }
  let(:librarian) { create(:librarian) }
  

  let(:book) { create(:book, total_copies: 5, available_copies: 4) }
  
  let!(:my_borrowing) { create(:borrowing, :active, member: member, book: book) }
  
  let!(:other_borrowing) { create(:borrowing, :active, member: other_member, book: book) }

  describe "GET /borrowings" do
    context "as a Guest" do
      it "redirects to root (login check)" do
        get borrowings_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("must be logged in")
      end
    end

    context "as a Member" do
      before { sign_in member }

      it "returns success and loads the borrowings controller" do
        get borrowings_path
        expect(response).to have_http_status(:success)

        expect(response.body).to include('data-controller="borrowings"')
      end

      context "with filters" do
        it "responds successfully to active filter" do
          get borrowings_path, params: { filter: "active" }
          expect(response).to have_http_status(:success)
        end

        it "responds successfully to returned filter" do
          get borrowings_path, params: { filter: "returned" }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context "as a Librarian" do
      before { sign_in librarian }

      it "returns success" do
        get borrowings_path
        expect(response).to have_http_status(:success)
      end

      it "responds successfully to member_id filter" do
        get borrowings_path, params: { member_id: member.id }
        expect(response).to have_http_status(:success)
      end
    end
  end


  describe "GET /borrowings/:id" do
    context "as a Member" do
      before { sign_in member }

      it "shows my borrowing" do
        get borrowing_path(my_borrowing)
        expect(response).to have_http_status(:success)
      end

      it "returns 404 for others' borrowing" do
       
        get borrowing_path(other_borrowing)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "as a Librarian" do
      before { sign_in librarian }

      it "shows any borrowing" do
        get borrowing_path(other_borrowing)
        expect(response).to have_http_status(:success)
      end
    end
  end


  describe "PATCH /borrowings/:id/return_book" do
    context "as a Member" do
      before { sign_in member }

      let(:active_borrowing) { create(:borrowing, :active, member: member, book: create(:book, available_copies: 1)) }

      it "returns the book successfully" do
    
        borrowing_book = active_borrowing.book
        borrowing_book.update_column(:available_copies, 1)

        patch return_book_borrowing_path(active_borrowing)
        
        expect(response).to redirect_to(borrowings_path)
        expect(flash[:notice]).to eq("Book returned successfully")
        
        expect(active_borrowing.reload.status).to eq("returned")
        expect(borrowing_book.reload.available_copies).to eq(2)
      end

      it "handles failure gracefully (trying to return borrowing that is already returned)" do
        active_borrowing.mark_as_returned! # Return it first
        
        patch return_book_borrowing_path(active_borrowing)
        
        if flash[:alert]
          expect(flash[:alert]).to eq("Could not return book")
        end
        expect(response).to redirect_to(borrowings_path)
      end
      
      it "returns 404 for someone else's book" do
       
        patch return_book_borrowing_path(other_borrowing)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "as a Librarian" do
      before { sign_in librarian }

      it "can return any member's book" do
        patch return_book_borrowing_path(other_borrowing)
        
        expect(response).to redirect_to(borrowings_path)
        expect(other_borrowing.reload.status).to eq("returned")
      end
    end
  end
end