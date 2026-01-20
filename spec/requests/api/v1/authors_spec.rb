require 'rails_helper'

RSpec.describe "Api::V1::Authors", type: :request do
  let!(:author) { create(:author, name: "J.K. Rowling") }
  let!(:book) { create(:book, title: "Harry Potter", authors: [ author ]) }


  let(:librarian) { create(:admin_user) }
  let(:member) { create(:member) }


  def auth_headers(user)
    token = Doorkeeper::AccessToken.create!(resource_owner_id: user.id).token
    { 'Authorization': "Bearer #{token}" }
  end

  describe "GET /api/v1/authors" do
    let!(:other_author) { create(:author, name: "George R.R. Martin") }

    it "returns a list of authors" do
      get api_v1_authors_path

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['authors'].length).to eq(2)
      expect(json).to have_key('meta')
    end

    it "filters by search term" do
      get api_v1_authors_path, params: { search: "Rowling" }

      json = JSON.parse(response.body)
      expect(json['authors'].length).to eq(1)
      expect(json['authors'].first['name']).to eq("J.K. Rowling")
    end
  end

  describe "GET /api/v1/authors/:id" do
    let!(:approved_review) { create(:review, :approved, reviewable: author, reviewer: create(:member)) }
    let!(:member_pending)  { create(:review, :pending, reviewable: author, reviewer: member) }
    let!(:other_pending)   { create(:review, :pending, reviewable: author, reviewer: create(:member)) }

    context "when public (unauthenticated)" do
      it "returns author details and ONLY approved reviews" do
        get api_v1_author_path(author)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        review_ids = json['reviews'].map { |r| r['id'] }
        expect(review_ids).to include(approved_review.id)
        expect(review_ids).not_to include(member_pending.id)
        expect(review_ids).not_to include(other_pending.id)
      end
    end

    context "when authenticated as Member" do
      before do
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:member_signed_in?).and_return(true)
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:current_member).and_return(member)
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:librarian_signed_in?).and_return(false)
      end

      it "returns approved reviews PLUS member's own pending reviews" do
        get api_v1_author_path(author), headers: auth_headers(member)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        review_ids = json['reviews'].map { |r| r['id'] }

        expect(review_ids).to include(approved_review.id)
        expect(review_ids).to include(member_pending.id)
        expect(review_ids).not_to include(other_pending.id)
      end
    end

    context "when authenticated as Librarian" do
      before do
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:librarian_signed_in?).and_return(true)
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:member_signed_in?).and_return(false)
      end

      it "returns ALL reviews (approved and pending)" do
        get api_v1_author_path(author), headers: auth_headers(librarian)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        review_ids = json['reviews'].map { |r| r['id'] }

        expect(review_ids).to include(approved_review.id)
        expect(review_ids).to include(member_pending.id)
        expect(review_ids).to include(other_pending.id)
      end
    end

    it "returns 404 if author not found" do
      get api_v1_author_path(id: 0)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/authors" do
    let(:valid_params) { { author: { name: "New Author", biography: "Bio", birth_date: "1990-01-01" } } }

    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:authenticate_librarian!).and_return(true)
      end

      it "creates a new author" do
        expect {
          post api_v1_authors_path, params: valid_params
        }.to change(Author, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "returns errors for invalid data" do
        post api_v1_authors_path, params: { author: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to have_key('errors')
      end
    end

    context "as a Member" do
      it "returns forbidden" do
        post api_v1_authors_path, params: valid_params, headers: auth_headers(member)
        expect(response.status).to be_in([ 403 ])
      end
    end
  end

  describe "PUT /api/v1/authors/:id" do
    let(:update_params) { { author: { name: "Updated Name" } } }

    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:authenticate_librarian!).and_return(true)
      end

      it "updates the author" do
        put api_v1_author_path(author), params: update_params

        expect(response).to have_http_status(:success)
        expect(author.reload.name).to eq("Updated Name")
      end

      it "returns errors for invalid update" do
        put api_v1_author_path(author), params: { author: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as a Member" do
      it "prevents update" do
        put api_v1_author_path(author), params: update_params, headers: auth_headers(member)

        expect(response.status).to be_in([ 403 ])
        expect(author.reload.name).not_to eq("Updated Name")
      end
    end
  end

  describe "DELETE /api/v1/authors/:id" do
    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::AuthorsController).to receive(:authenticate_librarian!).and_return(true)
      end

      it "deletes the author" do
        expect {
          delete api_v1_author_path(author)
        }.to change(Author, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it "handles failed deletion (integrity constraint mockup)" do
        allow_any_instance_of(Author).to receive(:destroy).and_return(false)

        delete api_v1_author_path(author)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("Could not delete author. They might be linked to active records.")
      end
    end

    context "as a Guest" do
      it "prevents deletion" do
        delete api_v1_author_path(author)
        expect(response.status).to be_in([ 401 ])
      end
    end
  end
end
