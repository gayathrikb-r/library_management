module Api
  module V1
    class MembersController < BaseController
      before_action :set_member
      before_action :authorize_member_access!

      # GET /api/v1/members/:id
      def show
        render json: @member.as_json(only: [ :id, :name, :email, :phone, :bio, :birth_date ])
      end

      # GET /api/v1/members/:id/activity
      def activity
        unless librarian_signed_in?
          return render json: { error: "Not authorized" }, status: :forbidden
        end

        stats = {
          total_borrowings: @member.borrowings.count,
          active_borrowings: @member.borrowings.active.count,
          overdue_borrowings: @member.borrowings.overdue.count,
          total_reservations: @member.reservations.count,
          pending_reservations: @member.reservations.pending.count
        }

        render json: stats
      end

      # PATCH/PUT /api/v1/members/:id
      def update
        if @member.update(member_params)
          render json: {
            message: "Profile updated successfully",
            member: @member.as_json(only: [ :id, :name, :email, :phone, :bio, :birth_date ])
          }
        else
          render json: {
            errors: @member.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      private

      def set_member
        @member = ::Member.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Member not found" }, status: :not_found
      end

      def authorize_member_access!
        return if librarian_signed_in?

        if member_signed_in?
          return if current_member == @member
        end

        render json: { error: "Not authorized" }, status: :forbidden
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
