require 'rails_helper'

RSpec.describe "Authors", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:librarian) { create(:librarian, name: "Librarian Name") }
  let(:member)    { create(:member) }
  let!(:author)   { create(:author, name: "J.R.R. Tolkien") }

  describe "GET /authors" do
    it "returns http success" do
      get authors_path
      expect(response).to have_http_status(:success)
    end

    it "accepts search params" do
      get authors_path, params: { search: "Tolkien" }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /authors/:id" do
    let!(:approved_review) do
      create(
        :review,
        :approved,
        reviewable: author,
        comment: "Approved Review"
      )
    end

    context "as a Guest" do
      it "returns success" do
        get author_path(author)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a Member" do
      before { sign_in member }

      it "returns success" do
        get author_path(author)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "returns success" do
        get author_path(author)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /authors/new" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "returns http success" do
        get new_author_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as Member" do
      before { sign_in member }

      it "redirects (unauthorized)" do
        get new_author_path
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "POST /authors" do
    let(:valid_params) do
      {
        author: {
          name: "New Author",
          biography: "Bio",
          birth_date: "1980-01-01"
        }
      }
    end

    let(:invalid_params) { { author: { name: "" } } }

    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "creates author and redirects" do
        expect {
          post authors_path, params: valid_params
        }.to change(Author, :count).by(1)

        expect(response).to redirect_to(author_path(Author.last))
      end

      it "renders new on failure" do
        expect {
          post authors_path, params: invalid_params
        }.not_to change(Author, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /authors/:id/edit" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "returns http success" do
        get edit_author_path(author)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /authors/:id" do
    let(:update_params) { { author: { name: "Updated Name" } } }
    let(:invalid_update) { { author: { name: "" } } }

    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "updates author and redirects" do
        patch author_path(author), params: update_params

        expect(response).to redirect_to(author_path(author))
        expect(author.reload.name).to eq("Updated Name")
      end

      it "renders edit on failure" do
        patch author_path(author), params: invalid_update

        expect(response).to have_http_status(:unprocessable_content)
        expect(author.reload.name).not_to eq("")
      end
    end
  end

  describe "DELETE /authors/:id" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "deletes the author and returns 204 No Content" do
        author_to_delete = create(:author)

        expect {
          delete author_path(author_to_delete)
        }.to change(Author, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it "returns JSON error if destroy fails" do
        allow_any_instance_of(Author).to receive(:destroy).and_return(false)

        delete author_path(author)

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to have_key("errors")
      end
    end

    context "as Member" do
      before { sign_in member }

      it "redirects (unauthorized)" do
        delete author_path(author)
        expect(response).to have_http_status(:found)
      end
    end
  end
end
