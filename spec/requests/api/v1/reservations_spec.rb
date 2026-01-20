require 'rails_helper'

RSpec.describe "Api::V1::Reservations", type: :request do
  let(:member) { create(:member) }
  let(:other_member) { create(:member) }
  let(:book) { create(:book, total_copies: 1, available_copies: 0) }


  let(:headers) { { "ACCEPT" => "application/json" } }

  describe "GET /api/v1/reservations" do
    let!(:reservation) { create(:reservation, member: member, book: book) }
    let!(:other_reservation) { create(:reservation, member: other_member, book: book) }

    context "as Member" do
      before do
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:authenticate_member!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:current_member).and_return(member)
      end

      it "returns only own reservations" do
        get api_v1_reservations_path, headers: headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        ids = json.map { |r| r['id'] }

        expect(ids).to include(reservation.id)
        expect(ids).not_to include(other_reservation.id)
      end
    end

    context "as Guest" do
      it "returns 401/403" do
        get api_v1_reservations_path, headers: headers
        expect(response.status).to be_in([ 401, 403 ])
      end
    end
  end

  describe "GET /api/v1/reservations/:id" do
    let!(:reservation) { create(:reservation, member: member, book: book) }

    context "as Owner" do
      before do
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:authenticate_member!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:current_member).and_return(member)
      end

      it "returns reservation details" do
        get api_v1_reservation_path(reservation), headers: headers

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(reservation.id)
        expect(json).to have_key('book')
        expect(json).to have_key('member')
      end
    end

    context "as Stranger" do
      before do
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:authenticate_member!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:current_member).and_return(other_member)
      end

      it "returns 404 (Not Found)" do
        get api_v1_reservation_path(reservation), headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/reservations" do
    let(:valid_params) { { reservation: { book_id: book.id } } }

    context "as Member" do
      before do
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:authenticate_member!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:current_member).and_return(member)
      end

      it "creates a reservation successfully" do
        expect {
          post api_v1_reservations_path, params: valid_params, headers: headers
        }.to change(Reservation, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "returns errors if reservation is invalid" do
        create(:reservation, member: member, book: book, status: :pending)

        post api_v1_reservations_path, params: valid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json).to have_key('errors')
      end
    end
  end

  # custom api
  describe "PATCH /api/v1/reservations/:id/cancel" do
    let!(:reservation) { create(:reservation, status: :pending, member: member, book: book) }

    context "as Owner" do
      before do
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:authenticate_member!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:current_member).and_return(member)
      end

      it "cancels the reservation" do
        patch cancel_api_v1_reservation_path(reservation), headers: headers

        expect(response).to have_http_status(:success)
        expect(reservation.reload.status).to eq('cancelled')
        expect(JSON.parse(response.body)['message']).to eq("Reservation cancelled successfully")
      end

      it "returns specific message if already cancelled" do
        reservation.update(status: :cancelled)

        patch cancel_api_v1_reservation_path(reservation), headers: headers

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['message']).to eq("Reservation is already cancelled")
      end

      it "handles cancellation failure (mocked)" do
        allow_any_instance_of(Reservation).to receive(:cancel!).and_return(false)

        patch cancel_api_v1_reservation_path(reservation), headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['error']).to eq("Could not cancel reservation")
      end
    end

    context "as Stranger" do
      before do
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:authenticate_member!).and_return(true)
        allow_any_instance_of(Api::V1::ReservationsController).to receive(:current_member).and_return(other_member)
      end

      it "returns 404 (Not Found)" do
        patch cancel_api_v1_reservation_path(reservation), headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
