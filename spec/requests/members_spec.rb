require 'rails_helper'

RSpec.describe "Members", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:other_member) { create(:member) }
  let(:librarian) { create(:librarian) }

  let(:valid_params) do
    {
      member: {
        name: "Updated Name",
        phone: "1234567890",
        bio: "Updated bio",
        birth_date: "1995-01-01"
      }
    }
  end

  let(:invalid_params) do
    {
      member: {
        name: ""
      }
    }
  end



  describe "authentication" do
    it "redirects guest users" do
      get member_path(member)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /members/:id" do
    context "as the same member" do
      before { sign_in member }

      it "returns success" do
        get member_path(member)
        expect(response).to have_http_status(:success)
      end
    end

    context "as librarian" do
      before { sign_in librarian }

      it "returns success" do
        get member_path(member)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a different member" do
      before { sign_in other_member }

      it "redirects (not authorized)" do
        get member_path(member)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when member does not exist" do
      before { sign_in librarian }

      it "redirects with not found" do
        get member_path(999999)
        expect(response).to redirect_to(root_path)
      end
    end
  end


  describe "GET /members/:id/edit" do
    context "as the same member" do
      before { sign_in member }

      it "returns success" do
        get edit_member_path(member)
        expect(response).to have_http_status(:success)
      end
    end

    context "as librarian" do
      before { sign_in librarian }

      it "returns success" do
        get edit_member_path(member)
        expect(response).to have_http_status(:success)
      end
    end
  end



  describe "PATCH /members/:id" do
    context "as the same member" do
      before { sign_in member }

      it "updates the profile successfully" do
        patch member_path(member), params: valid_params
        expect(response).to redirect_to(member_path(member))
        expect(member.reload.name).to eq("Updated Name")
      end

      it "renders edit on failure" do
        patch member_path(member), params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as librarian" do
      before { sign_in librarian }

      it "can update member profile" do
        patch member_path(member), params: valid_params
        expect(response).to redirect_to(member_path(member))
      end
    end

    context "as different member" do
      before { sign_in other_member }

      it "redirects (not authorized)" do
        patch member_path(member), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
