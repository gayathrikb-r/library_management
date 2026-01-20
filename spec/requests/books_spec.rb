require 'rails_helper'

RSpec.describe "Books", type: :request do
  include Devise::Test::IntegrationHelpers

  let!(:book) { create(:book, title: "Original Title", total_copies: 5, available_copies: 5) }
  let(:librarian) { create(:librarian) }
  let(:member) { create(:member) }


  describe "GET /books" do
    it "returns http success and loads the books controller" do
      get books_path
      expect(response).to have_http_status(:success)


      expect(response.body).to include('data-controller="books"')
    end

    it "filters by availability (URL params check)" do
      get books_path, params: { available: "true" }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /books/:id" do
    let!(:approved_review) { create(:review, :approved, reviewable: book, comment: "Public Review") }

    context "as a guest" do
      it "loads the book show controller" do
        get book_path(book)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-controller="book-show"')
      end
    end

    context "as a member" do
      before { sign_in member }

      it "loads successfully with member data attributes" do
        get book_path(book)

        expect(response).to have_http_status(:success)

        expect(response.body).to include('data-member-signed-in="true"')
      end
    end

    context "as a librarian" do
      before { sign_in librarian }

      it "loads successfully with librarian data attributes" do
        get book_path(book)

        expect(response).to have_http_status(:success)

        expect(response.body).to include('data-librarian-signed-in="true"')
      end
    end

    context "when book does not exist" do
      it "redirects to index" do
        get book_path("invalid-id")

        expect(response).to redirect_to(books_path)
        follow_redirect!
        expect(response.body).to include('data-controller="books"')
      end
    end
  end


  describe "Librarian Management" do
    let(:valid_attributes) { { title: "New Book", total_copies: 5, isbn: "12345" } }
    let(:invalid_attributes) { { title: "", total_copies: 5 } }

    context "when NOT signed in (Guest)" do
      it "redirects create to login" do
        post books_path, params: { book: valid_attributes }

        expect(response).to redirect_to(new_librarian_session_path)
      end

      it "redirects update to login" do
        patch book_path(book), params: { book: { title: "Hacked" } }
        expect(response).to redirect_to(new_librarian_session_path)
      end
    end

    context "when signed in as Librarian" do
      before { sign_in librarian }


      describe "POST /books" do
        context "with valid params" do
          it "creates a new Book and redirects" do
            expect {
              post books_path, params: { book: valid_attributes }
            }.to change(Book, :count).by(1)

            expect(response).to redirect_to(Book.last)
          end
        end

        context "with invalid params" do
          it "renders new template" do
            post books_path, params: { book: invalid_attributes }
            expect(response).to have_http_status(:unprocessable_content)
          end
        end
      end


      describe "PATCH /books/:id" do
        context "with valid params" do
          it "updates the requested book" do
            patch book_path(book), params: { book: { title: "Updated Title" } }
            expect(book.reload.title).to eq("Updated Title")
            expect(response).to redirect_to(book)
          end
        end

        context "with invalid params" do
          it "renders edit template" do
            patch book_path(book), params: { book: { title: "" } }
            expect(response).to have_http_status(:unprocessable_content)
          end
        end
      end


      describe "DELETE /books/:id" do
        it "destroys the requested book" do
          expect {
            delete book_path(book)
          }.to change(Book, :count).by(-1)
          expect(response).to redirect_to(books_path)
        end
      end
    end
  end


  describe "Member Actions" do
    context "when guest" do
      it "redirects borrow to member login" do
        post borrow_book_path(book)
        expect(response).to redirect_to(new_member_session_path)
      end
    end

    context "when signed in as Member" do
      before { sign_in member }


      describe "POST /books/:id/borrow" do
        it "borrows the book successfully" do
          expect {
            post borrow_book_path(book)
          }.to change(Borrowing, :count).by(1)

          expect(response).to redirect_to(member_dashboard_path)
        end
      end


      describe "POST /books/:id/reserve" do
        let(:unavailable_book) { create(:book, available_copies: 0) }

        it "reserves the book successfully" do
          expect {
            post reserve_book_path(unavailable_book)
          }.to change(Reservation, :count).by(1)

          expect(response).to redirect_to(member_dashboard_path)
        end
      end
    end
  end
end
