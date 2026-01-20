require 'rails_helper'

RSpec.describe "Reviews", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:other_member) { create(:member) }
  let(:librarian) { create(:librarian) }
  let(:book) { create(:book) }
  

  let!(:review) { create(:review, reviewable: book, reviewer: member, comment: "Original Comment", status: "pending") }

  describe "POST /books/:book_id/reviews" do
    let(:valid_params) { { review: { rating: 5, comment: "Great read! Highly recommend." } } }

    context "as a member" do

      let(:new_member) { create(:member) }
      before { sign_in new_member }

      it "creates a pending review" do
        expect {
          post book_reviews_path(book), params: valid_params
        }.to change(Review, :count).by(1)

        expect(Review.last.status).to eq("pending")
        expect(response).to redirect_to(book)
        follow_redirect!
        expect(response.body).to include("Review submitted")
      end
    end

    context "as a guest" do
      it "redirects to login" do
        post book_reviews_path(book), params: valid_params
        expect(response).to redirect_to(new_member_session_path)
      end
    end
  end


  describe "PATCH /reviews/:id" do
    let(:update_params) { { review: { comment: "Updated Comment Content" } } }

    context "as the review owner" do
      before { sign_in member }

      it "updates the review" do
        patch review_path(review), params: update_params
        expect(review.reload.comment).to eq("Updated Comment Content")
        expect(response).to redirect_to(book)
      end
    end

    context "as another member" do
      before { sign_in other_member }

      it "denies access" do
        patch review_path(review), params: update_params
        expect(review.reload.comment).to eq("Original Comment")
        expect(response).to redirect_to(book)
        follow_redirect!
        expect(response.body).to include("not authorized")
      end
    end

    context "as a librarian" do
      before { sign_in librarian }

      it "updates the review (moderation)" do
        patch review_path(review), params: { review: { comment: "Moderated Content" } }
        expect(review.reload.comment).to eq("Moderated Content")
      end
    end
  end

  describe "DELETE /reviews/:id" do
    context "as the review owner" do
      before { sign_in member }
      it "deletes the review" do
        expect { delete review_path(review) }.to change(Review, :count).by(-1)
      end
    end

    context "as a librarian" do
      before { sign_in librarian }
      it "deletes the review" do
        expect { delete review_path(review) }.to change(Review, :count).by(-1)
      end
    end

    context "as another member" do
      before { sign_in other_member }
      it "denies access" do
        expect { delete review_path(review) }.not_to change(Review, :count)
        expect(response).to redirect_to(book)
      end
    end
  end


  describe "PATCH /reviews/:id/flag" do
    before { review.update!(status: "approved") }

    context "as any signed in user" do
      before { sign_in other_member }

      it "flags the review" do
        patch flag_review_path(review)
        expect(review.reload.status).to eq("pending")
        expect(response).to redirect_to(book)
        follow_redirect!
        expect(response.body).to include("Review flagged")
      end
    end
  end

  describe "PATCH /reviews/:id/approve" do
    context "as a librarian" do
      before { sign_in librarian }

      it "approves the review" do
        patch approve_review_path(review)
        expect(review.reload.status).to eq("approved")
        expect(response).to redirect_to(book)
        follow_redirect!
        expect(response.body).to include("Review approved")
      end
    end

    context "as a member" do
      before { sign_in member }

      it "denies approval rights" do
        patch approve_review_path(review)
        
        expect(review.reload.status).to eq("pending")
        
        expect(response).to redirect_to(book)
        follow_redirect!
        expect(response.body).to include("Only librarians can approve")
      end
    end
  end
end