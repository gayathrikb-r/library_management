module Api
  module V1
    class BooksController < BaseController
      before_action :set_book, only: [:show, :update, :destroy, :borrow, :reserve]
      def index
        books = Book.includes(:authors, :categories)
                    .search(params[:search])
                    .by_category(params[:category_id])
        
        books = books.available if params[:available] == "true"
        books = books.page(params[:page]).per(params[:per_page] || 12)
        render json: books, include: [:authors, :categories]
      end
      def show
        reviews = @book.reviews.approved.includes(:reviewer)
        render json: {
          book: @book.as_json(include: [:authors, :categories]),
          reviews: reviews
        }
      end
      def create
        book = Book.create!(book_params)
        render json: book, status: :created
      end

      def update
        @book.update!(book_params)
        render json: @book
      end
      def destroy
        @book.destroy!
        head :no_content 
      end
      def borrow
        borrowing = current_user.borrowings.build(book: @book)
        
        if borrowing.save
          render json: { 
            message: "Book borrowed successfully", 
            due_date: borrowing.due_date,
            book: @book 
          }, status: :ok
        else
          render json: { errors: borrowing.errors.full_messages }, status: :unprocessable_entity
        end
      end
      def reserve
        reservation = current_user.reservations.build(book: @book)
        
        if reservation.save
          render json: { 
            message: "Book reserved successfully", 
            book: @book 
          }, status: :ok
        else
          render json: { errors: reservation.errors.full_messages }, status: :unprocessable_entity
        end
      end
      private

      def set_book
        @book = Book.find(params[:id])
      end

      def book_params
        params.require(:book).permit(
          :title, :isbn, :publication_year,
          :total_copies, :available_copies, :description,
          author_ids: [], category_ids: []
        )
      end
    end
  end
end