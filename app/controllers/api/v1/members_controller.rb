module Api
  module V1
    class MembersController < BaseController
      before_action :set_member


      # GET /api/v1/members/:id
      def show
        render json: @member
      end

      # PATCH/PUT /api/v1/members/:id
      def update
        @member.update!(member_params)
        render json: { message: "Profile updated successfully", member: @member }
      end

      private

      def set_member
        @member = Member.find(params[:id])
      end

      def authorize_member_access!
        return if librarian_signed_in?
        if member_signed_in?
          return if current_member == @member
        end
        render json: { error: "Not authorized" }, status: :forbidden
      end

      def authenticate_any_user!
        unless member_signed_in? || librarian_signed_in?
          render json: { error: "Please sign in" }, status: :unauthorized
        end
      end

      def member_params
        params.require(:member).permit(
          :name,
          :phone,
          :bio,
          :birth_date
        )
      end
    end
  end
end