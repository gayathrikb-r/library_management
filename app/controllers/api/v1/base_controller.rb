
module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Backend
      include Doorkeeper::Rails::Helpers


      before_action :doorkeeper_authorize!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_content
      rescue_from ActionController::ParameterMissing do |e|
        render json: { error: e.message }, status: :bad_request
      end

      private


      def current_resource_owner
        return @current_resource_owner if defined?(@current_resource_owner)
        return @current_resource_owner = nil unless doorkeeper_token

        token_id = doorkeeper_token.resource_owner_id
        token_type = doorkeeper_token.resource_owner_type

        @current_resource_owner = if token_type.present?
          Object.const_get(token_type).find_by(id: token_id)
        else
          ::Member.find_by(id: token_id) || ::Librarian.find_by(id: token_id)
        end
      end

      def current_member
        owner = current_resource_owner
        owner if owner.is_a?(::Member)
      end

      def current_librarian
        owner = current_resource_owner
        owner if owner.is_a?(::Librarian)
      end

      def member_signed_in?
        !!current_member
      end

      def librarian_signed_in?
        !!current_librarian
      end


      def authenticate_member!
        unless member_signed_in?
          render json: { error: "Member access required" }, status: :forbidden
        end
      end

      def authenticate_librarian!
        unless librarian_signed_in?
          render json: { error: "Librarian access required" }, status: :forbidden
        end
      end

      def not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def unprocessable_content (exception)
        render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_content
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end

      def doorkeeper_unauthorized_render_options(error: nil)
        { json: { error: "Not authorized. Please provide a valid token." } }
      end

      def pagination_meta(pagy)
        {
          current_page: pagy.page,
          total_pages: pagy.pages,
          total_count: pagy.count,
          per_page: pagy.limit
        }
      end
    end
  end
end
