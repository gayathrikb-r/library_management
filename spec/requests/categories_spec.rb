require 'rails_helper'

RSpec.describe "Categories", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:librarian) do
    user = create(:admin_user)
    user.define_singleton_method(:name) { "Librarian Name" }
    user
  end

  let(:member) { create(:member) }
  let!(:category) { create(:category, name: "Science Fiction") }
  let!(:book) { create(:book, title: "Dune", categories: [ category ]) }


  describe "GET /categories" do
    it "is accessible to guests" do
      get categories_path
      expect(response).to have_http_status(:success)
    end

    it "is accessible to members" do
      sign_in member
      get categories_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /categories/:id" do
    it "shows category page" do
      get category_path(category)
      expect(response).to have_http_status(:success)
    end
  end



  describe "GET /categories/new" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "returns success" do
        get new_category_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as Guest" do
      it "redirects to login" do
        get new_category_path
        expect(response).to redirect_to(new_librarian_session_path)
      end
    end
  end

  describe "POST /categories" do
    let(:valid_params) { { category: { name: "Fantasy" } } }
    let(:invalid_params) { { category: { name: "" } } }

    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "creates a new category" do
        expect {
          post categories_path, params: valid_params
        }.to change(Category, :count).by(1)

        expect(response).to redirect_to(categories_path)
      end

      it "renders new on failure" do
        expect {
          post categories_path, params: invalid_params
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as Member" do
      before { sign_in member }

      it "redirects (unauthorized)" do
        post categories_path, params: valid_params
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "GET /categories/:id/edit" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "returns success" do
        get edit_category_path(category)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /categories/:id" do
    let(:update_params) { { category: { name: "Sci-Fi" } } }
    let(:invalid_params) { { category: { name: "" } } }

    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "updates the category" do
        patch category_path(category), params: update_params
        expect(response).to redirect_to(categories_path)


        expect(category.reload.name).to eq("Sci Fi")
      end

      it "renders edit on failure" do
        patch category_path(category), params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(category.reload.name).to eq("Science Fiction")
      end
    end
  end

  describe "DELETE /categories/:id" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "deletes the category" do
        category_to_delete = create(:category)

        expect {
          delete category_path(category_to_delete)
        }.to change(Category, :count).by(-1)

        expect(response).to redirect_to(categories_path)
      end
    end

    context "as Guest" do
      it "redirects to login" do
        delete category_path(category)
        expect(response).to redirect_to(new_librarian_session_path)
      end
    end
  end
end
