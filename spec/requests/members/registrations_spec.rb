require 'rails_helper'

RSpec.describe "Members::Registrations", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:valid_attributes) do
    {
      member: {
        name: "New Member",
        email: "newmember@example.com",
        phone: "1234567890",
        password: "password123",
        password_confirmation: "password123"
      }
    }
  end

  let(:invalid_attributes) do
    {
      member: {
        name: "New Member",
        email: "newmember@example.com",
        password: "password123",
        password_confirmation: "mismatch"
      }
    }
  end

  describe "POST /members/sign_up" do
    context "Happy Path (Success)" do
      it "creates a new member and redirects" do
        expect {
          post member_registration_path, params: valid_attributes
        }.to change(Member, :count).by(1)


        expect(response).to have_http_status(:redirect)


        expect(flash[:errors]).to be_nil
      end
    end

    context "Inactive Account Path" do
      before do
        allow_any_instance_of(Member).to receive(:active_for_authentication?).and_return(false)
        allow_any_instance_of(Member).to receive(:inactive_message).and_return(:locked)
      end

      it "creates the member but redirects to the inactive path" do
        expect {
          post member_registration_path, params: valid_attributes
        }.to change(Member, :count).by(1)


        expect(response).to have_http_status(:redirect)

        expect(controller.current_member).to be_nil
      end
    end

    context "Sad Path (Validation Failure)" do
      it "renders the new template with unprocessable_content  status" do
        expect {
          post member_registration_path, params: invalid_attributes
        }.not_to change(Member, :count)


        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
