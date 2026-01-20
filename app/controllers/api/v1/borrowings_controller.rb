module Api
  module V1
    class BorrowingsController < BaseController
      before_action :set_borrowing, only: [ :show, :return_book ]

      def index
        borrowings = if librarian_signed_in?
          params[:member_id].present? ?
            Borrowing.where(member_id: params[:member_id]) :
            Borrowing.all
        elsif member_signed_in?
          current_member.borrowings
        else
          return render json: { error: "User not identified" }, status: :unauthorized
        end

        borrowings = borrowings.includes(:book, :member)

        if params[:filter].present?
          case params[:filter]
          when "active"   then borrowings = borrowings.where(status: :borrowed)
          when "overdue"  then borrowings = borrowings.where(status: :overdue)
          when "returned" then borrowings = borrowings.where(status: :returned)
          end
        end

        render json: borrowings.order(created_at: :desc).as_json(
          include: {
            book: { only: [ :id, :title ] },
            member: { only: [ :id, :name ] }
          },
          methods: [ :days_overdue ]
        )
      end

      def show
        render json: @borrowing.as_json(
          include: {
            book: { only: [ :id, :title ] },
            member: { only: [ :id, :name ] }
          },
          methods: [ :days_overdue ]
        )
      end

      def return_book
        if @borrowing.status == "returned"
          return render json: { error: "Book already returned" }, status: :unprocessable_content
        end

        if @borrowing.mark_as_returned!
          render json: {
            message: "Book returned successfully",
            borrowing: @borrowing.reload
          }, status: :ok
        else
          render json: { error: "Could not return book" }, status: :unprocessable_content
        end
      end

      private

      def set_borrowing
        if librarian_signed_in?
          @borrowing = Borrowing.find(params[:id])
        elsif member_signed_in?
          @borrowing = current_member.borrowings.find(params[:id])
        else
          raise ActiveRecord::RecordNotFound
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Borrowing not found" }, status: :not_found
      end
    end
  end
end
