require 'rails_helper'

RSpec.describe "Members::Passwords", type: :request do
  include Devise::Test::IntegrationHelpers

  let!(:member) { create(:member, email: "existing@example.com") }

  describe "POST /members/password" do
    
    context "when email exists" do
      it "sends reset instructions and redirects to login" do

        expect {
          post member_password_path, params: { member: { email: "existing@example.com" } }
        }.to change(ActionMailer::Base.deliveries, :size).by(1)


        expect(response).to redirect_to(new_member_session_path)

     
        expect(flash[:notice]).to eq("If your email exists in our system, you will receive reset instructions shortly.")
      end
    end

    context "when email does not exist" do
      it "redirects exactly the same way to prevent user enumeration" do
      
        expect {
          post member_password_path, params: { member: { email: "ghost@example.com" } }
        }.not_to change(ActionMailer::Base.deliveries, :size)

  
        expect(response).to redirect_to(new_member_session_path)

     
        expect(flash[:notice]).to eq("If your email exists in our system, you will receive reset instructions shortly.")
      end
    end

   context "parameter handling" do
      it "filters parameters using email_params and returns 400 if missing" do
        post member_password_path, params: {}
        
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end