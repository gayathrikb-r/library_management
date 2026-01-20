require 'rails_helper'

RSpec.describe "Api::V1::Categories", type: :request do
  let!(:category) { create(:category, name: "Science Fiction") }

  let!(:book) { create(:book, title: "Dune", categories: [ category ]) }

  let(:librarian) { create(:admin_user) }
  let(:member) { create(:member) }


  def auth_headers(user)
    token = Doorkeeper::AccessToken.create!(resource_owner_id: user.id).token
    { 'Authorization': "Bearer #{token}" }
  end

  describe "GET /api/v1/categories" do
    let!(:other_category) { create(:category, name: "Fantasy") }

    it "returns a list of categories with pagination meta" do
      get api_v1_categories_path

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json['categories'].length).to eq(2)
      expect(json).to have_key('meta')


      expect(json['categories'].first).to have_key('books_count')
    end
  end

  describe "GET /api/v1/categories/:id" do
    it "returns category details and associated books" do
      get api_v1_category_path(category)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json['category']['id']).to eq(category.id)
      expect(json['books']).to be_an(Array)
      expect(json['books'].first['title']).to eq("Dune")


      expect(json['books'].first).to have_key('authors')
    end

    it "returns 404 if category not found" do
      get api_v1_category_path(id: 0)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/categories" do
    let(:valid_params) { { category: { name: "History" } } }

    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::CategoriesController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::CategoriesController).to receive(:authenticate_librarian!).and_return(true)
      end

      it "creates a new category" do
        expect {
          post api_v1_categories_path, params: valid_params
        }.to change(Category, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "returns errors for invalid data" do
        post api_v1_categories_path, params: { category: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json).to have_key('errors')
      end
    end

    context "as a Member" do
      it "returns unauthorized/forbidden" do
        post api_v1_categories_path, params: valid_params, headers: auth_headers(member)
        expect(response.status).to be_in([ 401, 403, 302 ])
      end
    end
  end

  describe "PUT /api/v1/categories/:id" do
    let(:update_params) { { category: { name: "Sci-Fi" } } }

    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::CategoriesController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::CategoriesController).to receive(:authenticate_librarian!).and_return(true)
      end

      it "updates the category" do
        put api_v1_category_path(category), params: update_params

        expect(response).to have_http_status(:success)
       expect(category.reload.name).to eq("Sci Fi")
      end

      it "returns errors for invalid update" do
        put api_v1_category_path(category), params: { category: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as a Member" do
      it "prevents update" do
        put api_v1_category_path(category), params: update_params, headers: auth_headers(member)
        expect(response.status).to be_in([ 401, 403, 302 ])
      end
    end
  end

  describe "DELETE /api/v1/categories/:id" do
    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::CategoriesController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::CategoriesController).to receive(:authenticate_librarian!).and_return(true)
      end

      it "deletes the category" do
        cat_to_delete = create(:category)

        expect {
          delete api_v1_category_path(cat_to_delete)
        }.to change(Category, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it "handles failed deletion (mocking failure)" do
        allow_any_instance_of(Category).to receive(:destroy).and_return(false)

        delete api_v1_category_path(category)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json).to have_key('errors')
      end
    end

    context "as a Member" do
      it "prevents deletion" do
        delete api_v1_category_path(category), headers: auth_headers(member)
        expect(response.status).to be_in([ 401, 403, 302 ])
      end
    end
  end
end
