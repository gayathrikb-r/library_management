require 'rails_helper'

RSpec.describe "Api::V1::Librarians::Dashboard", type: :request do

  let(:librarian) { create(:admin_user) }
  let(:member) { create(:member) }
  let(:member_two) { create(:member) } 


  let!(:book) { create(:book, title: "Dune", total_copies: 5, available_copies: 5) }
  
 
  let!(:active_borrowing) { create(:borrowing, status: :borrowed, book: book, member: member) }
  let!(:overdue_borrowing) { create(:borrowing, :overdue, book: book, member: member) }
  

  let!(:pending_reservation) { create(:reservation, status: :pending, book: book, member: member, skip_availability_check: true) }
  
  let!(:pending_review) { create(:review, status: :pending, reviewable: book, reviewer: member, comment: "Pending approval") }
  let!(:approved_review) { create(:review, status: :approved, reviewable: book, reviewer: member_two) }


  def auth_headers(user)
    token = Doorkeeper::AccessToken.create!(resource_owner_id: user.id).token
    { 'Authorization': "Bearer #{token}" }
  end

  describe "GET /api/v1/librarians/dashboard" do
    context "as a Librarian" do
      before do
        
        allow_any_instance_of(Api::V1::Librarians::DashboardController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::Librarians::DashboardController).to receive(:authenticate_librarian!).and_return(true)
      end

      it "returns 200 OK with correct stats structure" do
        get api_v1_librarians_dashboard_path
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)


        stats = json['stats']
        expect(stats['total_books']).to eq(Book.count)
        expect(stats['total_members']).to eq(Member.count)
        
        expect(stats).to have_key('active_borrowings')
        expect(stats).to have_key('overdue_borrowings')
        expect(stats['pending_reservations']).to eq(1)
        expect(stats['pending_reviews']).to eq(1)
      end

      it "returns correct Overdue Books data" do
        get api_v1_librarians_dashboard_path
        json = JSON.parse(response.body)
        
        overdue_data = json['overdue_books']
        expect(overdue_data).to be_an(Array)
        
        item = overdue_data.find { |b| b['id'] == overdue_borrowing.id }
        expect(item).to be_present
        expect(item['book']['title']).to eq("Dune")
        expect(item['member']['name']).to eq(member.name)
        expect(item).to have_key('days_overdue')
      end

      it "returns correct Pending Reviews data" do
        get api_v1_librarians_dashboard_path
        json = JSON.parse(response.body)
        
        reviews_data = json['pending_reviews']
        expect(reviews_data.length).to eq(1) # Only the pending one
        
        item = reviews_data.first
        expect(item['id']).to eq(pending_review.id)
        expect(item['reviewer']['name']).to eq(member.name)
        expect(item['reviewable_title']).to eq("Dune")
        expect(item['comment']).to eq("Pending approval")
      end

      it "returns correct Recent Borrowings data" do
        get api_v1_librarians_dashboard_path
        json = JSON.parse(response.body)
        
        borrowings_data = json['recent_borrowings']
        ids = borrowings_data.map { |b| b['id'] }
        expect(ids).to include(active_borrowing.id)
        expect(ids).to include(overdue_borrowing.id)
        
        item = borrowings_data.first
        expect(item).to have_key('status')
        expect(item).to have_key('created_at')
      end

      it "returns correct Pending Reservations data" do
        get api_v1_librarians_dashboard_path
        json = JSON.parse(response.body)
        
        reservations_data = json['pending_reservations']
        expect(reservations_data.length).to eq(1)
        
        item = reservations_data.first
        expect(item['id']).to eq(pending_reservation.id)
        expect(item['book']['title']).to eq("Dune")
      end
    end

    context "as a Member" do
      it "returns unauthorized/forbidden" do
        get api_v1_librarians_dashboard_path, headers: auth_headers(member)
        expect(response.status).to be_in([401, 403, 302])
      end
    end

    context "as Guest" do
      it "returns unauthorized" do
        get api_v1_librarians_dashboard_path
        expect(response.status).to be_in([401, 403, 302])
      end
    end
  end
end