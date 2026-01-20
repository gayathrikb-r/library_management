module Api
  module V1
    class BooksController < BaseController
      before_action :set_book, only: [ :show, :update, :destroy, :borrow, :reserve ]

      skip_before_action :doorkeeper_authorize!, only: [ :index, :show ]

      before_action :authenticate_member!, only: [ :borrow, :reserve ]
      before_action :authenticate_librarian!, only: [ :create, :update, :destroy ]

      def index
        books_query = Book.includes(:authors, :categories)
                          .search(params[:search])
                          .by_category(params[:category_id])

        books_query = books_query.available if params[:available] == "true"

        pagy, books = pagy(books_query, limit: params[:per_page] || 12)

        render json: {
          books: books.as_json(include: [ :authors, :categories ], methods: [ :available_copies ]),
          meta: pagination_meta(pagy)
        }
      end

      def show
        reviews_scope = @book.reviews.includes(:reviewer).order(created_at: :desc)

        if librarian_signed_in?
          @reviews = reviews_scope
        elsif member_signed_in?
          @reviews = reviews_scope.where(status: :approved)
                                  .or(reviews_scope.where(reviewer: current_member))
        else
          @reviews = reviews_scope.approved
        end

        render json: {
          book: @book.as_json(include: [ :authors, :categories ], methods: [ :available_copies ]),
          reviews: @reviews.as_json(include: { reviewer: { only: [ :id, :name ] } })
        }
      end

      def create
        clean_params = book_params.to_h
        new_authors_list = process_mixed_input(clean_params.delete("new_author_names"))
        new_categories_list = process_mixed_input(clean_params.delete("new_category_names"))

        @book = Book.new(clean_params)

        new_authors_list.each do |name|
          author = Author.find_or_create_by(name: name)
          @book.authors << author
        end

        new_categories_list.each do |name|
          category = Category.find_or_create_by(name: name)
          @book.categories << category
        end

        if @book.save
          render json: @book, status: :created
        else
          render json: { errors: @book.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        clean_params = book_params.to_h
        new_authors_list = process_mixed_input(clean_params.delete("new_author_names"))
        new_categories_list = process_mixed_input(clean_params.delete("new_category_names"))

        if @book.update(clean_params)
          new_authors_list.each do |name|
            author = Author.find_or_create_by(name: name)
            @book.authors << author unless @book.authors.exists?(author.id)
          end

          new_categories_list.each do |name|
            category = Category.find_or_create_by(name: name)
            @book.categories << category unless @book.categories.exists?(category.id)
          end

          render json: @book.reload
        else
          render json: { errors: @book.errors.full_messages }, status: :unprocessable_content
        end
      end
      def destroy
        if @book.destroy
          render json: {
            message: "Book deleted successfully",
            book_id: @book.id
          }, status: :ok
        else
          render json: { errors: @book.errors.full_messages }, status: :unprocessable_content
        end
      end


      def borrow
        borrowing = current_member.borrowings.build(book: @book)

        if borrowing.save
          render json: {
            message: "Book borrowed successfully",
            due_date: borrowing.due_date,
            book: @book
          }, status: :ok
        else
          render json: { errors: borrowing.errors.full_messages }, status: :unprocessable_content
        end
      end

      def reserve
        reservation = current_member.reservations.build(book: @book)

        if reservation.save
          render json: {
            message: "Book reserved successfully",
            book: @book
          }, status: :ok
        else
          render json: { errors: reservation.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      def set_book
        @book = Book.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Book not found" }, status: :not_found
      end

      def process_mixed_input(input)
        return [] if input.blank?

        if input.is_a?(String)
          input.split(",").map(&:strip).reject(&:empty?)
        elsif input.is_a?(Array)
          input.map(&:strip).reject(&:empty?)
        else
          []
        end
      end

      def book_params
        params.require(:book).permit(
          :title, :isbn, :publication_year,
          :total_copies, :available_copies, :description,
          { author_ids: [] }, { category_ids: [] },
          { new_author_names: [] }, { new_category_names: [] },
          :new_author_names, :new_category_names
        )
      end
    end
  end
end
