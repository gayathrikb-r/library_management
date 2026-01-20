require 'rails_helper'

RSpec.describe "Api::V1::Member::Dashboard", type: :request do

  let(:member) { create(:member) }
  let(:other_member) { create(:member) }
  let(:book) { create(:book, title: "The Hobbit", total_copies: 5, available_copies: 5) }
  let(:book2) { create(:book, title: "1984", total_copies: 3, available_copies: 3) }
  

  let(:headers) { { "ACCEPT" => "application/json" } }

  

  let!(:my_borrowing) { create(:borrowing, book: book, member: member, status: :borrowed, due_date: 2.days.from_now) }
  let!(:my_returned) { create(:borrowing, status: :returned, book: book, member: member) } 
  let!(:my_overdue) { create(:borrowing, :overdue, book: book, member: member) }
  
  let!(:other_borrowing) { create(:borrowing, book: book, member: other_member, status: :borrowed) } 


  let!(:my_reservation) { create(:reservation, book: book, member: member, status: :pending, skip_availability_check: true) }
  let!(:my_fulfilled_res) { create(:reservation, book: book2, member: member, status: :fulfilled, skip_availability_check: true) } 
  let!(:other_reservation) { create(:reservation, book: book2, member: other_member, status: :pending, skip_availability_check: true) } 

 let!(:my_review) { create(:review, reviewable: book, reviewer: member, rating: 5, comment: "Great read!", status: :approved) }
  let!(:other_review) { create(:review, reviewable: book, reviewer: other_member, rating: 1, comment: "Boring book, not recommended.") }
  
  describe "GET /api/v1/member/dashboard" do
    context "as an Authenticated Member" do
      before do
     
        allow_any_instance_of(Api::V1::Member::DashboardController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::Member::DashboardController).to receive(:authenticate_member!).and_return(true)
        allow_any_instance_of(Api::V1::Member::DashboardController).to receive(:current_member).and_return(member)
      end

      it "returns http success" do
        get api_v1_member_dashboard_path, headers: headers
        expect(response).to have_http_status(:success)
      end

      it "returns correct Borrowings (Active & Overdue only)" do
        get api_v1_member_dashboard_path, headers: headers
        json = JSON.parse(response.body)
        
        borrowing_ids = json['borrowings'].map { |b| b['id'] }
        

        expect(borrowing_ids).to include(my_borrowing.id)
        expect(borrowing_ids).to include(my_overdue.id)
        
  
        expect(borrowing_ids).not_to include(my_returned.id)
        expect(borrowing_ids).not_to include(other_borrowing.id)
        

        first_borrowing = json['borrowings'].find { |b| b['id'] == my_borrowing.id }
        expect(first_borrowing['book']['title']).to eq("The Hobbit")
        expect(first_borrowing).to have_key('days_overdue')
      end

      it "returns correct Reservations (Pending only)" do
        get api_v1_member_dashboard_path, headers: headers
        json = JSON.parse(response.body)
        
        reservation_ids = json['reservations'].map { |r| r['id'] }
        
 
        expect(reservation_ids).to include(my_reservation.id)
        

        expect(reservation_ids).not_to include(my_fulfilled_res.id)
        expect(reservation_ids).not_to include(other_reservation.id)
        

        expect(json['reservations'].first['book']['title']).to eq("The Hobbit")
      end

      it "returns correct Recent Reviews" do
        get api_v1_member_dashboard_path, headers: headers
        json = JSON.parse(response.body)
        
        review_ids = json['recent_reviews'].map { |r| r['id'] }
        

        expect(review_ids).to include(my_review.id)
        expect(review_ids).not_to include(other_review.id)

        review_data = json['recent_reviews'].first
        expect(review_data['reviewable_title']).to eq("The Hobbit")
        expect(review_data['rating']).to eq(5)
        expect(review_data['comment']).to eq("Great read!")
      end
    end

    context "as a Guest (Unauthenticated)" do
      it "returns unauthorized" do
        get api_v1_member_dashboard_path, headers: headers

        expect(response.status).to be_in([401, 403])
      end
    end
  end
end