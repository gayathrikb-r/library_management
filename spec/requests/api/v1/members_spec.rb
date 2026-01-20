require 'rails_helper'

RSpec.describe "Api::V1::Members", type: :request do
  let!(:member) { create(:member, name: "Original Name", bio: "Original Bio") }
  let!(:other_member) { create(:member) }
  let!(:librarian) { create(:admin_user) }


  let!(:active_borrowing) { create(:borrowing, status: :borrowed, member: member, book: create(:book, available_copies: 1)) }
  let!(:overdue_borrowing) { create(:borrowing, :overdue, member: member, book: create(:book, available_copies: 1)) }
  let!(:reservation) { create(:reservation, status: :pending, member: member, book: create(:book, available_copies: 0)) }

  def auth_headers(user)
    token = Doorkeeper::AccessToken.create!(resource_owner_id: user.id).token
    { 'Authorization': "Bearer #{token}" }
  end

  describe "GET /api/v1/members/:id" do
    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::MembersController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:librarian_signed_in?).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:member_signed_in?).and_return(false)
      end

      it "returns the member details" do
        get api_v1_member_path(member)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(member.id)
        expect(json['name']).to eq("Original Name")
      end

      it "returns 404 if member not found" do
        get api_v1_member_path(id: 0)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "as the Member themselves (Owner)" do
      before do
        allow_any_instance_of(Api::V1::MembersController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:librarian_signed_in?).and_return(false)
        allow_any_instance_of(Api::V1::MembersController).to receive(:member_signed_in?).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:current_member).and_return(member)
      end

      it "allows access to own profile" do
        get api_v1_member_path(member)
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['id']).to eq(member.id)
      end
    end

    context "as another Member (Stranger)" do
      before do
        allow_any_instance_of(Api::V1::MembersController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:librarian_signed_in?).and_return(false)
        allow_any_instance_of(Api::V1::MembersController).to receive(:member_signed_in?).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:current_member).and_return(other_member)
      end

      it "returns forbidden (403)" do
        get api_v1_member_path(member)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /api/v1/members/:id/activity" do
    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::MembersController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:librarian_signed_in?).and_return(true)
      end

      it "returns the member's activity stats" do
        get activity_api_v1_member_path(member)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        # Borrowings: 1 active + 1 overdue = 2 total
        expect(json['total_borrowings']).to eq(2)
        expect(json['active_borrowings']).to eq(1)
        expect(json['overdue_borrowings']).to eq(1)

        # Reservations: 1 pending
        expect(json['total_reservations']).to eq(1)
        expect(json['pending_reservations']).to eq(1)
      end
    end

    context "as the Member themselves" do
      before do
        allow_any_instance_of(Api::V1::MembersController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:librarian_signed_in?).and_return(false)
        allow_any_instance_of(Api::V1::MembersController).to receive(:member_signed_in?).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:current_member).and_return(member)
      end

      it "returns forbidden (only librarians can see raw stats via this endpoint)" do
        get activity_api_v1_member_path(member)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v1/members/:id" do
    let(:valid_params) { { member: { name: "New Name", bio: "New Bio" } } }
    let(:invalid_params) { { member: { name: "" } } }

    context "as the Member themselves (Owner)" do
      before do
        allow_any_instance_of(Api::V1::MembersController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:librarian_signed_in?).and_return(false)
        allow_any_instance_of(Api::V1::MembersController).to receive(:member_signed_in?).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:current_member).and_return(member)
      end

      it "updates the profile successfully" do
        patch api_v1_member_path(member), params: valid_params

        expect(response).to have_http_status(:success)
        expect(member.reload.name).to eq("New Name")
        expect(member.bio).to eq("New Bio")
      end

      it "returns errors for invalid data" do
        patch api_v1_member_path(member), params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json).to have_key('errors')
      end
    end

    context "as another Member (Stranger)" do
      before do
        allow_any_instance_of(Api::V1::MembersController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:librarian_signed_in?).and_return(false)
        allow_any_instance_of(Api::V1::MembersController).to receive(:member_signed_in?).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:current_member).and_return(other_member)
      end

      it "prevents update" do
        patch api_v1_member_path(member), params: valid_params
        expect(response).to have_http_status(:forbidden)
        expect(member.reload.name).to eq("Original Name")
      end
    end

    context "as a Librarian" do
      before do
        allow_any_instance_of(Api::V1::MembersController).to receive(:doorkeeper_authorize!).and_return(true)
        allow_any_instance_of(Api::V1::MembersController).to receive(:librarian_signed_in?).and_return(true)
      end

      it "allows updating any member" do
        patch api_v1_member_path(member), params: valid_params
        expect(response).to have_http_status(:success)
        expect(member.reload.name).to eq("New Name")
      end
    end
  end
end
