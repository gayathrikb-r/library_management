require 'rails_helper'

RSpec.describe 'Api::V1::Books', type: :request do
  let(:member) { create(:member) }
  let(:librarian) { create(:librarian) }

  let(:member_token) do
    create(:access_token, resource_owner_id: member.id, resource_owner_type: 'Member', scopes: 'public member').token
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

  def json
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/books' do
    let!(:book1) { create(:book, title: 'Ruby on Rails', available_copies: 1) }
    let!(:book2) { create(:book, title: 'Advanced Ruby', available_copies: 0) }
    let(:category) { create(:category) }

    before do
      book1.categories << category
    end

    context 'public access' do
      it 'returns list of books with pagination meta' do
        get '/api/v1/books'
        expect(response).to have_http_status(:ok)
        expect(json['books'].size).to eq(2)
        expect(json).to have_key('meta')
      end

      it 'filters by search term' do
        get '/api/v1/books', params: { search: 'Rails' }
        titles = json['books'].map { |b| b['title'] }
        expect(titles).to include('Ruby on Rails')
        expect(titles).not_to include('Advanced Ruby')
      end

      it 'filters by availability' do
        get '/api/v1/books', params: { available: 'true' }
        ids = json['books'].map { |b| b['id'] }
        expect(ids).to include(book1.id)
        expect(ids).not_to include(book2.id)
      end

      it 'filters by category_id' do
        get '/api/v1/books', params: { category_id: category.id }
        expect(json['books'].size).to eq(1)
        expect(json['books'].first['id']).to eq(book1.id)
      end
    end
  end

  describe 'GET /api/v1/books/:id' do
    let(:book) { create(:book) }
    let!(:approved_review) { create(:review, :approved, reviewable: book, comment: "This is a public approved comment.") }
    let!(:pending_review) { create(:review, :pending, reviewable: book, comment: "This is a hidden pending comment.") }
    let!(:my_pending_review) { create(:review, :pending, reviewable: book, reviewer: member, comment: "This is my own pending comment.") }

    context 'as guest' do
      it 'sees only approved reviews' do
        get "/api/v1/books/#{book.id}"
        expect(response).to have_http_status(:ok)
        comments = json['reviews'].map { |r| r['comment'] }
        expect(comments).to eq([ "This is a public approved comment." ])
      end

      it 'returns 404 for missing book' do
        get "/api/v1/books/0"
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'as member' do
      before do
        allow_any_instance_of(Api::V1::BooksController).to receive(:member_signed_in?).and_return(true)
        allow_any_instance_of(Api::V1::BooksController).to receive(:current_member).and_return(member)
      end

      it 'sees approved reviews AND their own pending reviews' do
        get "/api/v1/books/#{book.id}", headers: auth_headers(member_token)
        comments = json['reviews'].map { |r| r['comment'] }
        expect(comments).to include("This is a public approved comment.", "This is my own pending comment.")
        expect(comments).not_to include("This is a hidden pending comment.")
      end
    end

    context 'as librarian' do
      before do
        allow_any_instance_of(Api::V1::BooksController).to receive(:librarian_signed_in?).and_return(true)
      end

      it 'sees ALL reviews' do
        get "/api/v1/books/#{book.id}", headers: auth_headers(librarian_token)
        expect(json['reviews'].size).to eq(3)
      end
    end
  end

  describe 'POST /api/v1/books' do
    let(:valid_params) do
      {
        book: {
          title: "New Book",
          isbn: "1234567890",
          total_copies: 10,
          publication_year: 2024,
          description: "Description"
        }
      }
    end

    context 'as librarian' do
      before do
        allow_any_instance_of(Api::V1::BooksController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::BooksController).to receive(:authenticate_librarian!).and_return(true)
      end

      it 'creates a book with new authors (Array input)' do
        params = valid_params.deep_merge(book: { new_author_names: [ "Author A", "Author B" ] })

        expect {
          post '/api/v1/books', params: params.to_json, headers: auth_headers(librarian_token)
        }.to change(Book, :count).by(1).and change(Author, :count).by(2)
        expect(response).to have_http_status(:created)
      end

      it 'creates a book with new categories (String CSV input)' do
        params = valid_params.deep_merge(book: { new_category_names: "Mystery, Thriller" })

        expect {
          post '/api/v1/books', params: params.to_json, headers: auth_headers(librarian_token)
        }.to change(Category, :count).by(2)

        expect(Book.last.categories.pluck(:name)).to include("Mystery", "Thriller")
      end

      it 'ignores invalid input types (e.g., Integer) for mixed input' do
        params = valid_params.deep_merge(book: { new_author_names: 12345 })

        expect {
          post '/api/v1/books', params: params.to_json, headers: auth_headers(librarian_token)
        }.to change(Book, :count).by(1)

        expect(Book.last.authors).to be_empty
      end

      it 'handles blank/nil input gracefully' do
        params = valid_params.deep_merge(book: { new_author_names: nil })
        post '/api/v1/books', params: params.to_json, headers: auth_headers(librarian_token)
        expect(response).to have_http_status(:created)
      end

      it 'returns error when params are invalid' do
        post '/api/v1/books', params: { book: { title: "" } }.to_json, headers: auth_headers(librarian_token)
        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to be_present
      end
    end

    context 'as member' do
      it 'returns forbidden' do
        post '/api/v1/books', params: valid_params.to_json, headers: auth_headers(member_token)
        expect(response.status).to be_in([ 401, 403, 302 ])
      end
    end
  end

  describe 'PUT /api/v1/books/:id' do
    let!(:book) { create(:book) }

    context 'as librarian' do
      before do
        allow_any_instance_of(Api::V1::BooksController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::BooksController).to receive(:authenticate_librarian!).and_return(true)
      end

      it 'updates book and adds new author' do
        params = { book: { title: "Updated Title", new_author_names: "New Guy" } }
        put "/api/v1/books/#{book.id}", params: params.to_json, headers: auth_headers(librarian_token)

        expect(response).to have_http_status(:ok)
        expect(book.reload.title).to eq("Updated Title")
        expect(book.authors.pluck(:name)).to include("New Guy")
      end

      it 'does not duplicate existing authors' do
        existing_author = create(:author, name: "Existing Guy")
        book.authors << existing_author

        params = { book: { new_author_names: "Existing Guy" } }

        expect {
          put "/api/v1/books/#{book.id}", params: params.to_json, headers: auth_headers(librarian_token)
        }.not_to change(book.authors, :count)
      end

      it 'updates book and adds new categories' do
        params = { book: { new_category_names: "Horror, Comedy" } }

        expect {
          put "/api/v1/books/#{book.id}", params: params.to_json, headers: auth_headers(librarian_token)
        }.to change(Category, :count).by(2)

        expect(book.reload.categories.pluck(:name)).to include("Horror", "Comedy")
      end

      it 'does not duplicate existing categories' do
        existing_category = create(:category, name: "Drama")
        book.categories << existing_category

        params = { book: { new_category_names: "Drama" } }

        expect {
          put "/api/v1/books/#{book.id}", params: params.to_json, headers: auth_headers(librarian_token)
        }.not_to change(book.categories, :count)
      end

      it 'returns error on invalid update' do
        put "/api/v1/books/#{book.id}", params: { book: { title: "" } }.to_json, headers: auth_headers(librarian_token)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /api/v1/books/:id' do
    let!(:book) { create(:book) }

    context 'as librarian' do
      before do
        allow_any_instance_of(Api::V1::BooksController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::BooksController).to receive(:authenticate_librarian!).and_return(true)
      end

      it 'deletes the book' do
        expect {
          delete "/api/v1/books/#{book.id}", headers: auth_headers(librarian_token)
        }.to change(Book, :count).by(-1)
        expect(response).to have_http_status(:ok)
      end

      it 'returns error if deletion fails' do
        allow_any_instance_of(Book).to receive(:destroy).and_return(false)
        delete "/api/v1/books/#{book.id}", headers: auth_headers(librarian_token)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
  # custom api
  describe 'POST /api/v1/books/:id/borrow' do
    let(:book) { create(:book, available_copies: 1) }

    context 'as member' do
      before do
        allow_any_instance_of(Api::V1::BooksController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::BooksController).to receive(:authenticate_member!).and_return(true)
        allow_any_instance_of(Api::V1::BooksController).to receive(:current_member).and_return(member)
      end

      it 'creates a borrowing' do
        expect {
          post "/api/v1/books/#{book.id}/borrow", headers: auth_headers(member_token)
        }.to change(Borrowing, :count).by(1)
        expect(response).to have_http_status(:ok)
      end

      it 'returns error if book unavailable' do
        unavailable_book = create(:book, available_copies: 0)
        post "/api/v1/books/#{unavailable_book.id}/borrow", headers: auth_headers(member_token)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  # custom api
  describe 'POST /api/v1/books/:id/reserve' do
    let(:book) { create(:book, available_copies: 0) }

    context 'as member' do
      before do
        allow_any_instance_of(Api::V1::BooksController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::BooksController).to receive(:authenticate_member!).and_return(true)
        allow_any_instance_of(Api::V1::BooksController).to receive(:current_member).and_return(member)
      end

      it 'creates a reservation' do
        expect {
          post "/api/v1/books/#{book.id}/reserve", headers: auth_headers(member_token)
        }.to change(Reservation, :count).by(1)
        expect(response).to have_http_status(:ok)
      end

      it 'returns error if reservation invalid' do
        create(:reservation, book: book, member: member, status: :pending)

        expect {
          post "/api/v1/books/#{book.id}/reserve", headers: auth_headers(member_token)
        }.not_to change(Reservation, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
