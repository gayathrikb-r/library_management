require 'rails_helper'

RSpec.describe "Librarians::Reviews", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:librarian) do
    user = create(:admin_user)

    user.define_singleton_method(:name) { "Librarian Name" }
    user
  end

  let(:member) { create(:member) }
  let(:book) { create(:book, title: "Reviewable Book") }
  

  let!(:review) { create(:review, reviewable: book, reviewer: member, status: :pending) }

  describe "GET /librarians/reviews (Index)" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "returns http success and loads reviews" do
        get librarians_reviews_path
        expect(response).to have_http_status(:success)
       
        expect(response.body).to include("Reviewable Book")
      end
    end

    context "as Guest" do
      it "redirects to login page" do
        get librarians_reviews_path
        expect(response).to redirect_to(new_librarian_session_path)
      end
    end
  end

  describe "GET /librarians/reviews/:id (Show)" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "returns http success" do
        get librarians_review_path(review)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(review.comment) if review.comment.present?
      end
    end
  end

  describe "PATCH /librarians/reviews/:id/approve" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "approves the review and redirects to the book page" do
        expect {
          patch approve_librarians_review_path(review)
        }.to change { review.reload.status }.from('pending').to('approved')

        expect(response).to redirect_to(book_path(book))
        expect(flash[:notice]).to eq("Review approved successfully!")
      end

      it "handles approval failure gracefully" do

        allow_any_instance_of(Review).to receive(:update).and_return(false)
        allow_any_instance_of(Review).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return("Database locked")

        expect {
          patch approve_librarians_review_path(review)
        }.not_to change { review.reload.status }

        expect(response).to redirect_to(book_path(book))
        expect(flash[:alert]).to include("Could not approve review: Database locked")
      end
    end

    context "as Guest" do
      it "redirects to login page and does not approve" do
        expect {
          patch approve_librarians_review_path(review)
        }.not_to change { review.reload.status }
        
        expect(response).to redirect_to(new_librarian_session_path)
      end
    end
  end
end