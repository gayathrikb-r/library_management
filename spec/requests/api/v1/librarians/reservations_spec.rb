require 'rails_helper'

RSpec.describe "Api::V1::Librarians::Reservations", type: :request do
  # Factories
  let(:librarian) { create(:admin_user) }
  let(:member) { create(:member) }
  let(:member_two) { create(:member) }

  let(:book) { create(:book, total_copies: 5, available_copies: 5) }


  let(:headers) { { "ACCEPT" => "application/json" } }


  def json
    JSON.parse(response.body)
  end

  describe "GET /api/v1/librarians/reservations" do
    let!(:pending_res) { create(:reservation, status: :pending, book: book, member: member, skip_availability_check: true) }
    let!(:fulfilled_res) { create(:reservation, status: :fulfilled, book: book, member: member_two, skip_availability_check: true) }

    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::Librarians::ReservationsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::Librarians::ReservationsController).to receive(:authenticate_librarian!).and_return(true)
      end

      it "returns a list of ONLY pending reservations" do
        get api_v1_librarians_reservations_path, headers: headers

        expect(response).to have_http_status(:success)
        ids = json.map { |r| r['id'] }
        expect(ids).to include(pending_res.id)
        expect(ids).not_to include(fulfilled_res.id)
      end

      it "includes member and book details" do
        get api_v1_librarians_reservations_path, headers: headers

        reservation = json.find { |r| r['id'] == pending_res.id }
        expect(reservation).to have_key('member')
        expect(reservation['member']).to have_key('name')
        expect(reservation).to have_key('book')
        expect(reservation['book']).to have_key('title')
      end
    end

    context "as a Member" do
      it "returns unauthorized" do
        get api_v1_librarians_reservations_path, headers: headers

        expect(response.status).to be_in([ 401, 403 ])
      end
    end
  end


  describe "PATCH /api/v1/librarians/reservations/:id/fulfill" do
    let!(:reservation) { create(:reservation, status: :pending, book: book, member: member, skip_availability_check: true) }

    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::Librarians::ReservationsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::Librarians::ReservationsController).to receive(:authenticate_librarian!).and_return(true)
      end

      it "successfully fulfills the reservation" do
        patch fulfill_api_v1_librarians_reservation_path(reservation), headers: headers

        expect(response).to have_http_status(:success)
        expect(json['message']).to eq("Reservation fulfilled successfully")
        expect(reservation.reload.status).to eq("fulfilled")
      end

      it "returns 404 if reservation not found" do
        patch fulfill_api_v1_librarians_reservation_path(id: 0), headers: headers
        expect(response).to have_http_status(:not_found)
        expect(json['errors']).to include("Reservation not found")
      end

      context "when fulfillment fails (Model Logic)" do
        it "returns errors if book copies are insufficient" do
          reservation.book.update(available_copies: 0)

          patch fulfill_api_v1_librarians_reservation_path(reservation), headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['errors']).to be_present
        end
      end

      context "when fulfillment fails (Edge Case)" do
        it "returns a default error message" do
          allow_any_instance_of(Reservation).to receive(:fulfill!).and_return(false)
          allow_any_instance_of(Reservation).to receive_message_chain(:errors, :full_messages).and_return([])

          patch fulfill_api_v1_librarians_reservation_path(reservation), headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['errors']).to include("Unable to fulfill reservation")
        end
      end
    end
  end


  describe "PATCH /api/v1/librarians/reservations/:id/cancel" do
    let!(:reservation) { create(:reservation, status: :pending, book: book, member: member, skip_availability_check: true) }

    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::Librarians::ReservationsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::Librarians::ReservationsController).to receive(:authenticate_librarian!).and_return(true)
      end

      it "successfully cancels the reservation" do
        patch cancel_api_v1_librarians_reservation_path(reservation), headers: headers

        expect(response).to have_http_status(:success)
        expect(json['message']).to eq("Reservation cancelled successfully")
        expect(reservation.reload.status).to eq("cancelled")
      end

      context "when cancellation fails (Model Logic)" do
        it "returns errors if reservation is not pending" do
          reservation.update(status: :fulfilled)

          patch cancel_api_v1_librarians_reservation_path(reservation), headers: headers

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when cancellation fails (Edge Case)" do
        it "returns a default error message" do
          allow_any_instance_of(Reservation).to receive(:cancel!).and_return(false)
          allow_any_instance_of(Reservation).to receive_message_chain(:errors, :full_messages).and_return([])

          patch cancel_api_v1_librarians_reservation_path(reservation), headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['errors']).to include("Unable to cancel reservation")
        end
      end
    end
  end
end
