require 'rails_helper'

RSpec.describe "Member::Dashboard", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member, name: "John Doe") }
  let(:book) { create(:book, title: "Dashboard Book") }


  let!(:active_borrowing) { create(:borrowing, :active, member: member, book: book) }
  let!(:pending_reservation) { create(:reservation, :pending, member: member, book: book) }
  let!(:recent_review) { create(:review, reviewer: member, reviewable: book, created_at: 1.day.ago) }

  describe "GET /member/dashboard/show" do
    context "when authenticated" do
      before { sign_in member }

      it "returns http success and loads the dashboard structure" do
        get member_dashboard_path
        
        expect(response).to have_http_status(:success)
        
        
        expect(response.body).to include("Welcome, John Doe!")
        expect(response.body).to include("Active Borrowings")
        
        expect(response.body).to include('data-member-dashboard-target="borrowings"')
        expect(response.body).to include('data-member-dashboard-target="reservations"')
        
      end
    end

    context "when unauthenticated" do
      it "redirects to the login page" do
        get member_dashboard_path
        expect(response).to redirect_to(new_member_session_path)
      end
    end
  end
end