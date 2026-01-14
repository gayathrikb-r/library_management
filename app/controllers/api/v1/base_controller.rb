
module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Backend
      # Enable Cookies/Sessions for Devise (Web Interface)
      include ActionController::Cookies
      include ActionController::RequestForgeryProtection
      
   
      include ActionController::Helpers
      include ActionController::MimeResponds

  
      before_action :doorkeeper_authorize!, unless: -> { user_signed_in_via_session? }

      #  Error Handling
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private
      def pagination_meta(pagy)
        {
          current_page: pagy.page,
          next_page: pagy.next,
          prev_page: pagy.prev,
          total_pages: pagy.pages,
          total_count: pagy.count
        }
      end
    

      def user_signed_in_via_session?
        warden&.authenticate(scope: :member) || warden&.authenticate(scope: :librarian)
      end


      def authenticate_member!
        unless current_member
          render json: { error: "Member authentication required" }, status: :unauthorized
        end
      end

      def authenticate_librarian!
        unless current_librarian
          render json: { error: "Librarian authentication required" }, status: :unauthorized
        end
      end
      def authenticate_request!
        if user_signed_in_via_session?
          puts "✅ User found via Session!"
          return
        end
        
        #  Otherwise, strictly require a valid API Token
        puts "⚠️ No Session found. Checking Doorkeeper..."
        doorkeeper_authorize!
      end

     

      def current_member
        @current_member ||= begin
          
          warden&.user(:member) || 
         
          (doorkeeper_token && current_resource_owner.is_a?(::Member) ? current_resource_owner : nil)
        end
      end

      def current_librarian
        @current_librarian ||= begin
          
          warden&.user(:librarian) || 
          (doorkeeper_token && current_resource_owner.is_a?(::Librarian) ? current_resource_owner : nil)
        end
      end

      def member_signed_in?
        !!current_member
      end

      def librarian_signed_in?
        !!current_librarian
      end

      def current_resource_owner
        return @resource_owner if defined?(@resource_owner)
        return nil unless doorkeeper_token
        
        @resource_owner = ::Member.find_by(id: doorkeeper_token.resource_owner_id) || 
                          ::Librarian.find_by(id: doorkeeper_token.resource_owner_id)
      end

      def warden
        request.env['warden']
      end


      def not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
      
      # This handles Doorkeeper failures (Invalid Token)
      def doorkeeper_unauthorized_render_options(error: nil)
        { json: { error: "Not authorized. Please log in or provide a valid token." } }
      end
    end
  end
end