require 'rails_helper'

RSpec.describe "Librarians::Reservations", type: :request do
  include Devise::Test::IntegrationHelpers
  include ActionView::RecordIdentifier

  let(:librarian) do
    user = create(:admin_user)
    user.define_singleton_method(:name) { "Librarian Name" }
    user
  end

  let(:member) { create(:member) }
  let(:book) { create(:book, total_copies: 5, available_copies: 5) }
  let!(:reservation) { create(:reservation, status: 'pending', book: book, member: member, skip_availability_check: true) }

  describe "GET /librarians/reservations" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "returns http success" do
        get librarians_reservations_path
        expect(response).to have_http_status(:success)
       
        expect(response.body).to include('data-controller="librarian-reservations"')
      end
    end

    context "as Guest" do
      it "redirects to login" do
        get librarians_reservations_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_librarian_session_path)
      end
    end
  end

  describe "PATCH /librarians/reservations/:id/fulfill" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "fulfills the reservation and redirects (HTML request)" do
        expect {
          patch fulfill_librarians_reservation_path(reservation)
        }.to change { reservation.reload.status }.from('pending').to('fulfilled')

        expect(response).to redirect_to(librarians_dashboard_path)
        
        expect(flash[:notice]).to eq("Reservation fulfilled")
      end

      it "fulfills the reservation and returns Turbo Stream" do
        headers = { "Accept" => "text/vnd.turbo-stream.html" }
        
        expect {
          patch fulfill_librarians_reservation_path(reservation), headers: headers
        }.to change { reservation.reload.status }.from('pending').to('fulfilled')

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq Mime[:turbo_stream]
        
 
        expect(response.body).to include('action="remove"')
        expect(response.body).to include(dom_id(reservation))
        expect(response.body).to include("Reservation fulfilled successfully")
      end
    end
  end

  describe "PATCH /librarians/reservations/:id/cancel" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "cancels the reservation and redirects (HTML request)" do
        expect {
          patch cancel_librarians_reservation_path(reservation)
        }.to change { reservation.reload.status }.from('pending').to('cancelled')

        expect(response).to redirect_to(librarians_dashboard_path)

        expect(flash[:alert]).to eq("Reservation cancelled")
      end

      it "cancels the reservation and returns Turbo Stream" do
        headers = { "Accept" => "text/vnd.turbo-stream.html" }
        
        expect {
          patch cancel_librarians_reservation_path(reservation), headers: headers
        }.to change { reservation.reload.status }.from('pending').to('cancelled')

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq Mime[:turbo_stream]
        

        expect(response.body).to include('action="remove"')
        expect(response.body).to include(dom_id(reservation))
        expect(response.body).to include("Reservation cancelled")
      end
    end
  end
end