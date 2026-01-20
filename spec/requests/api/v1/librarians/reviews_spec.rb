require 'rails_helper'

RSpec.describe "Api::V1::Librarians::Reviews", type: :request do
  # Use :admin_user factory consistent with other specs
  let(:librarian) { create(:admin_user) }
  let(:member) { create(:member) }
  let(:book1) { create(:book) }
  let(:book2) { create(:book) }

  let!(:approved_review) do
    create(:review, status: :approved, reviewer: member, reviewable: book1)
  end

  let!(:pending_review) do
    create(:review, status: :pending, reviewer: member, reviewable: book2)
  end

  let(:headers) do
    { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
  end

  # ----------------------------
  # STUB AUTHENTICATION
  # ----------------------------
  before do
    # FIX: Stub both Doorkeeper and Devise auth methods
    allow_any_instance_of(Api::V1::Librarians::ReviewsController)
      .to receive(:doorkeeper_authorize!)
      .and_return(true)

    allow_any_instance_of(Api::V1::Librarians::ReviewsController)
      .to receive(:authenticate_librarian!)
      .and_return(true)
  end

  # ----------------------------
  # INDEX
  # ----------------------------
  describe "GET /api/v1/librarians/reviews" do
    it "returns all reviews" do
      get api_v1_librarians_reviews_path, headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.size).to eq(2)
      expect(body.map { |r| r["id"] }).to include(approved_review.id, pending_review.id)
    end
  end

  # ----------------------------
  # SHOW
  # ----------------------------
  describe "GET /api/v1/librarians/reviews/:id" do
    it "returns a review" do
      get api_v1_librarians_review_path(approved_review), headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(approved_review.id)
    end

    it "returns 404 when review not found" do
      get api_v1_librarians_review_path(id: 999999), headers: headers

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Review not found")
    end
  end

  # ----------------------------
  # APPROVE
  # ----------------------------
  describe "PATCH /api/v1/librarians/reviews/:id/approve" do
    it "approves a review successfully" do
      patch approve_api_v1_librarians_review_path(pending_review), headers: headers

      expect(response).to have_http_status(:ok)
      expect(pending_review.reload.status).to eq("approved")
    end

    it "returns error when update fails" do
      # Mock the update call on the instance of the review that will be loaded
      allow_any_instance_of(Review).to receive(:update).and_return(false)
      allow_any_instance_of(Review).to receive_message_chain(:errors, :full_messages).and_return([ "Update failed" ])

      patch approve_api_v1_librarians_review_path(pending_review), headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["errors"]).to be_present
    end
  end

  # ----------------------------
  # AUTHORIZATION
  # ----------------------------
  describe "authorization" do
    it "blocks unauthenticated users" do
      # Unstub to test actual auth logic
      allow_any_instance_of(Api::V1::Librarians::ReviewsController)
        .to receive(:doorkeeper_authorize!)
        .and_call_original

      allow_any_instance_of(Api::V1::Librarians::ReviewsController)
        .to receive(:authenticate_librarian!)
        .and_call_original

      get api_v1_librarians_reviews_path, headers: headers

      # Expect 401 (Doorkeeper) or 302/403 (Devise)
      expect(response.status).to be_in([ 401, 403, 302 ])
    end
  end
end
