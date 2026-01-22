module Api
  module V1
    class ClientActionsController < BaseController

      # Enforce "Machine Only" access
      before_action :require_client_credentials!

      # GET /api/v1/system_stats
      def system_stats
        render json: { 
          status: "System Operational", 
          total_books: ::Book.count, 
          total_users: ::Member.count,
          timestamp: Time.current
        }
      end

      private

      def require_client_credentials!
        if doorkeeper_token.resource_owner_id.present?
          render json: { error: "Access denied. Machine authentication required." }, status: :forbidden
        end
      end
    end
  end
end
