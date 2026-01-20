require 'rails_helper'

RSpec.describe "Librarians::Dashboard", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:librarian) do
    user = create(:admin_user)

    user.define_singleton_method(:name) { "Librarian Name" }
    user
  end


  let!(:book) { create(:book, title: "Dashboard Book", total_copies: 20, available_copies: 20) }
  let!(:member) { create(:member, name: "Dashboard Member") }

  describe "GET /librarians/dashboard" do
    context "as Librarian" do
      before { sign_in librarian, scope: :librarian }

      it "returns http success and renders the dashboard skeleton" do
        get librarians_dashboard_path
        
        expect(response).to have_http_status(:success)

       
        expect(response.body).to include("Librarian Dashboard")
        expect(response.body).to include("Overdue Books")
        expect(response.body).to include("Pending Reviews")
        expect(response.body).to include("Recent Borrowings")
        
       
        expect(response.body).to include('data-controller="librarian-dashboard"')
        
     
      end
    end

    context "as Guest" do
      it "redirects to the login page" do
        get librarians_dashboard_path
        expect(response).to redirect_to(new_librarian_session_path)
      end
    end
  end
end