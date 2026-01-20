require 'rails_helper'

RSpec.describe "Api::V1::Reviews", type: :request do
  # Setup Users & Tokens
  let(:member) { create(:member) }
  let(:other_member) { create(:member) }
  let(:librarian) { create(:librarian) }

  let(:member_token) do
    create(:access_token, resource_owner_id: member.id, resource_owner_type: 'Member', scopes: 'public member').token
  end
  let(:other_member_token) do
    create(:access_token, resource_owner_id: other_member.id, resource_owner_type: 'Member', scopes: 'public member').token
  end
  let(:librarian_token) do
    create(:access_token, resource_owner_id: librarian.id, resource_owner_type: 'Librarian', scopes: 'public librarian').token
  end

  def auth_headers(token)
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }
  end

  # Setup Resources
  let(:book) { create(:book, title: "Reviewable Book") }
  let(:author) { create(:author, name: "Reviewable Author") }

  # Setup Reviews
  let!(:my_review) { create(:review, reviewable: book, reviewer: member, status: :pending, comment: "My original comment") }
  let!(:other_review) { create(:review, reviewable: book, reviewer: other_member, status: :pending) }

  # --- CREATE TESTS (Polymorphic & Errors) ---
  describe "POST /api/v1/books/:book_id/reviews" do
    let(:valid_params) { { review: { rating: 5, comment: "Great book!" } } }

    # FIX 1: Use a fresh book for creation tests to avoid uniqueness validation errors
    # (Since 'member' has already reviewed 'book' in the let! block above)
    let(:fresh_book) { create(:book, title: "Unread Book") }

    context "as member" do
      it "creates a review successfully" do
        expect {
          post "/api/v1/books/#{fresh_book.id}/reviews", params: valid_params.to_json, headers: auth_headers(member_token)
        }.to change(Review, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "returns 422 for invalid params" do
        invalid_params = { review: { rating: 6 } } # Invalid rating
        post "/api/v1/books/#{fresh_book.id}/reviews", params: invalid_params.to_json, headers: auth_headers(member_token)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns 404 if book not found (ActiveRecord Error)" do
        # This hits the 'rescue ActiveRecord::RecordNotFound' block
        post "/api/v1/books/0/reviews", params: valid_params.to_json, headers: auth_headers(member_token)
        expect(response).to have_http_status(:not_found)
      end

      # FIX 2: Coverage for Line 141 (Defensive Code)
      # We force Book.find to return nil instead of raising an error,
      # which causes the code to enter the 'unless @reviewable' block.
      it "returns 404 if finding reviewable returns nil (Defensive Check)" do
        allow(Book).to receive(:find).and_return(nil)

        post "/api/v1/books/#{fresh_book.id}/reviews", params: valid_params.to_json, headers: auth_headers(member_token)

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq("Reviewable not found")
      end
    end
  end

  describe "POST /api/v1/authors/:author_id/reviews" do
    let(:valid_params) { { review: { rating: 4, comment: "Great author!" } } }

    context "as member" do
      it "creates a review for an AUTHOR (polymorphic coverage)" do
        expect {
          post "/api/v1/authors/#{author.id}/reviews", params: valid_params.to_json, headers: auth_headers(member_token)
        }.to change(Review, :count).by(1)

        expect(Review.last.reviewable).to eq(author)
        expect(response).to have_http_status(:created)
      end
    end
  end

  # --- UPDATE TESTS (Authorization & Failures) ---
  describe "PUT /api/v1/reviews/:id" do
    let(:update_params) { { review: { comment: "Updated Comment" } } }

    context "as owner" do
      it "updates successfully" do
        put "/api/v1/reviews/#{my_review.id}", params: update_params.to_json, headers: auth_headers(member_token)
        expect(response).to have_http_status(:success)
        expect(my_review.reload.comment).to eq("Updated Comment")
      end

      it "returns 422 on update failure" do
        allow_any_instance_of(Review).to receive(:update).and_return(false)
        allow_any_instance_of(Review).to receive_message_chain(:errors, :full_messages).and_return([ "Validation failed" ])

        put "/api/v1/reviews/#{my_review.id}", params: update_params.to_json, headers: auth_headers(member_token)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as librarian" do
      it "can update any review" do
        put "/api/v1/reviews/#{my_review.id}", params: update_params.to_json, headers: auth_headers(librarian_token)
        expect(response).to have_http_status(:success)
      end
    end

    context "as other member" do
      it "returns forbidden" do
        put "/api/v1/reviews/#{other_review.id}", params: update_params.to_json, headers: auth_headers(member_token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "missing review" do
      it "returns 404" do
        put "/api/v1/reviews/0", params: update_params.to_json, headers: auth_headers(librarian_token)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # --- DESTROY TESTS ---
  describe "DELETE /api/v1/reviews/:id" do
    context "as owner" do
      it "deletes the review" do
        expect {
          delete "/api/v1/reviews/#{my_review.id}", headers: auth_headers(member_token)
        }.to change(Review, :count).by(-1)
        expect(response).to have_http_status(:success)
      end
    end

    context "as librarian" do
      it "deletes any review" do
        expect {
          delete "/api/v1/reviews/#{my_review.id}", headers: auth_headers(librarian_token)
        }.to change(Review, :count).by(-1)
        expect(response).to have_http_status(:success)
      end
    end

    context "as other member" do
      it "returns forbidden" do
        expect {
          delete "/api/v1/reviews/#{other_review.id}", headers: auth_headers(member_token)
        }.not_to change(Review, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # --- ACTION TESTS (Flag & Approve) ---
  describe "PATCH /api/v1/reviews/:id/flag" do
    context "as member" do
      it "flags the review" do
        patch "/api/v1/reviews/#{my_review.id}/flag", headers: auth_headers(member_token)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("moved to moderation")
      end

      it "returns 422 if flagging fails" do
        allow_any_instance_of(Review).to receive(:flag!).and_return(false)
        allow_any_instance_of(Review).to receive_message_chain(:errors, :full_messages).and_return([ "Flag failed" ])

        patch "/api/v1/reviews/#{my_review.id}/flag", headers: auth_headers(member_token)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /api/v1/reviews/:id/approve" do
    context "as librarian" do
      it "approves the review" do
        patch "/api/v1/reviews/#{my_review.id}/approve", headers: auth_headers(librarian_token)
        expect(response).to have_http_status(:ok)
        expect(my_review.reload.approved?).to be true
      end

      it "returns 422 if already approved" do
        my_review.update(status: :approved)
        patch "/api/v1/reviews/#{my_review.id}/approve", headers: auth_headers(librarian_token)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("already approved")
      end

      it "returns 422 if update fails" do
        allow_any_instance_of(Review).to receive(:update).and_return(false)
        allow_any_instance_of(Review).to receive_message_chain(:errors, :full_messages).and_return([ "Update failed" ])

        patch "/api/v1/reviews/#{my_review.id}/approve", headers: auth_headers(librarian_token)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
