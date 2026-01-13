module Api
  module V1
    class BorrowingsController < BaseController
      before_action :set_borrowing, only: [:show, :return_book]
      before_action :authenticate_any!

      def index
        borrowings = if librarian_signed_in?
                       params[:member_id].present? ? Borrowing.where(member_id: params[:member_id]) : Borrowing.all
                     else
                       current_member.borrowings
                     end

        borrowings = borrowings.includes(:book, :member)

        borrowings = case params[:filter]
                     when "active"   then borrowings.where(status: 'borrowed')
                     when "overdue"  then borrowings.where(status: 'overdue')
                     when "returned" then borrowings.where(status: 'returned')
                     else borrowings
                     end

        render json: borrowings.order(created_at: :desc).as_json(
          include: {
            book: { only: [:id, :title] },
            member: { only: [:id, :name] }
          },
          methods: [:days_overdue]
        )
      end

      def show
        render json: @borrowing.as_json(
          include: {
            book: { only: [:id, :title] },
            member: { only: [:id, :name] }
          },
          methods: [:days_overdue]
        )
      end

      def return_book
        if @borrowing.mark_as_returned!
          render json: { 
            message: "Book returned successfully", 
            borrowing: @borrowing 
          }, status: :ok
        else
          render json: { 
            error: "Could not return book" 
          }, status: :unprocessable_entity
        end
      end

      private

      def set_borrowing
        @borrowing = if librarian_signed_in?
                       Borrowing.find(params[:id])
                     else
                       current_member.borrowings.find(params[:id])
                     end
      end

      def authenticate_any!
        return if librarian_signed_in? || member_signed_in?
        render json: { error: "You must be logged in" }, status: :unauthorized
      end
    end
  end
end