module Api 
  module V1 
    class BaseController<ActionController::API
    before_action :set_default_format
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid,  with: :render_unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    private
    def set_default_format
        request.format = :json
    end
    def current_user
        @current_user ||= (current_librarian || current_member)
    end

    def render_not_found(exception)
        render json: { error: exception.message }, status: :not_found
    end

      def render_unprocessable_entity(exception)
        render json: { 
          error: "Validation Failed", 
          details: exception.record.errors.full_messages 
        }, status: :unprocessable_entity
      end

    def render_bad_request(exception)
      render json: { error: exception.message }, status: :bad_request
    end
    def render_unauthorized
        render json: { error: "Librarian access required for this action" }, status: :unauthorized
    end
  end
end
end