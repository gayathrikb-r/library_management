require 'rails_helper'

RSpec.describe 'Api::V1::Borrowings', type: :request do
  let(:member) { create(:member) }
  let(:librarian) { create(:librarian) }


  let(:member_token) do
    create(:access_token, resource_owner_id: member.id, resource_owner_type: 'Member', scopes: 'public member').token
  end

  let(:librarian_token) do
    create(:access_token, resource_owner_id: librarian.id, resource_owner_type: 'Librarian', scopes: 'public librarian').token
  end

  def json
    JSON.parse(response.body)
  end


  describe 'GET /api/v1/borrowings' do
    context 'as member' do
      let!(:my_borrowings) { create_list(:borrowing, 2, member: member) }
      let!(:other_borrowings) { create_list(:borrowing, 2) } # Belongs to another random member

      it 'returns only my borrowings' do
        get '/api/v1/borrowings', headers: { 'Authorization' => "Bearer #{member_token}" }

        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(2)
        expect(json.first['member']['id']).to eq(member.id)
      end

      it 'filters by status (active)' do
        create(:borrowing, :returned, member: member)
        active_borrowing = create(:borrowing, :active, member: member)

        get '/api/v1/borrowings',
            params: { filter: 'active' },
            headers: { 'Authorization' => "Bearer #{member_token}" }

        expect(response).to have_http_status(:ok)
        statuses = json.map { |b| b['status'] }
        expect(statuses).to include('borrowed')
        expect(statuses).not_to include('returned')
      end
    end

    context 'as librarian' do
      let!(:all_borrowings) { create_list(:borrowing, 5) }

      it 'returns all borrowings' do
        get '/api/v1/borrowings', headers: { 'Authorization' => "Bearer #{librarian_token}" }

        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(5)
      end

      it 'filters by member_id' do
        target_member = create(:member)
        create_list(:borrowing, 2, member: target_member)

        get '/api/v1/borrowings',
            params: { member_id: target_member.id },
            headers: { 'Authorization' => "Bearer #{librarian_token}" }

        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(2)
        expect(json.first['member']['id']).to eq(target_member.id)
      end
    end

    context 'unauthorized' do
      it 'returns 401 when no token is provided' do
        get '/api/v1/borrowings'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end


  describe 'GET /api/v1/borrowings/:id' do
    let(:borrowing) { create(:borrowing, member: member) }

    context 'as member' do
      it 'returns details for own borrowing' do
        get "/api/v1/borrowings/#{borrowing.id}",
            headers: { 'Authorization' => "Bearer #{member_token}" }

        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(borrowing.id)
        expect(json).to have_key('days_overdue')
      end

      it 'returns 404 for another member\'s borrowing' do
        other_borrowing = create(:borrowing)
        get "/api/v1/borrowings/#{other_borrowing.id}",
            headers: { 'Authorization' => "Bearer #{member_token}" }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # custom api
  describe 'PATCH /api/v1/borrowings/:id/return_book' do
    let(:book) { create(:book, available_copies: 1) }

    let(:borrowing) { create(:borrowing, :active, book: book, member: member) }

    context 'as member' do
      it 'successfully returns the book' do
        patch "/api/v1/borrowings/#{borrowing.id}/return_book",
              headers: { 'Authorization' => "Bearer #{member_token}" }

        expect(response).to have_http_status(:ok)
        expect(json['message']).to eq("Book returned successfully")
        expect(json['borrowing']['status']).to eq('returned')
      end

      it 'increments the book available copies' do
        target_book = borrowing.book


        target_book.update_column(:available_copies, 1)


        patch "/api/v1/borrowings/#{borrowing.id}/return_book",
              headers: { 'Authorization' => "Bearer #{member_token}" }


        expect(target_book.reload.available_copies).to eq(2)
      end
      it 'returns error if book is already returned' do
        borrowing.update!(status: :returned, returned_date: Date.today)

        patch "/api/v1/borrowings/#{borrowing.id}/return_book",
              headers: { 'Authorization' => "Bearer #{member_token}" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['error']).to match(/already returned/i)
      end
    end
  end
end
