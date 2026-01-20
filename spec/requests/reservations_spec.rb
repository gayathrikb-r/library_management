require 'rails_helper'

RSpec.describe "Reservations", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:other_member) { create(:member) }

  let(:book1) { create(:book, title: "Older Book") }
  let(:book2) { create(:book, title: "Newer Book") }

 
  let!(:reservation1) { create(:reservation, member: member, book: book1, created_at: 2.days.ago, skip_availability_check: true) }
  let!(:reservation2) { create(:reservation, member: member, book: book2, created_at: 1.day.ago, skip_availability_check: true) }

  let!(:other_reservation) { create(:reservation, member: other_member, skip_availability_check: true) }

  before { sign_in member }

  describe "GET /reservations" do
    it "returns http success and renders the reservations page" do
      get reservations_path
      expect(response).to have_http_status(:ok)
      

      expect(response.body).to include("Reservations")
    end
  end

  describe "GET /reservations/:id" do
    it "returns http success for own reservation" do
      get reservation_path(reservation1)
      expect(response).to have_http_status(:ok)
     
      expect(response.body).to include("Reservation")
    end

    it "prevents a member from viewing another member's reservation" do
      get reservation_path(other_reservation)
      
      expect(response).to redirect_to(reservations_path)
      expect(flash[:alert]).to eq("You are not authorized to access this reservation")
    end
  end

  describe "PATCH /reservations/:id/cancel" do
    it "allows a member to cancel their own reservation" do
      patch cancel_reservation_path(reservation1)
      
      expect(response).to redirect_to(reservations_path)
      expect(flash[:notice]).to eq("Reservation cancelled successfully")
      expect(reservation1.reload.status).to eq("cancelled")
    end

    it "prevents a member from cancelling another member's reservation" do
      patch cancel_reservation_path(other_reservation)
      
      expect(response).to redirect_to(reservations_path)
      expect(flash[:alert]).to eq("You are not authorized to access this reservation")
      expect(other_reservation.reload.status).not_to eq("cancelled")
    end
  end

  describe "Authentication" do
    it "redirects unauthenticated users from index" do
      sign_out member
      get reservations_path
      expect(response).to redirect_to(new_member_session_path)
    end

    it "redirects unauthenticated users from show" do
      sign_out member
      get reservation_path(reservation1)
      expect(response).to redirect_to(new_member_session_path)
    end

    it "redirects unauthenticated users from cancel" do
      sign_out member
      patch cancel_reservation_path(reservation1)
      expect(response).to redirect_to(new_member_session_path)
    end
  end
end