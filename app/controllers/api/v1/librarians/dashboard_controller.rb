module Api
  module V1
    module Librarians
      class DashboardController < BaseController
        before_action :authenticate_librarian!

        def index
          render json: {
            stats: {
              total_books: ::Book.count,
              total_members: ::Member.count,
              active_borrowings: ::Borrowing.borrowed.count,
              overdue_borrowings: ::Borrowing.overdue.count,
              pending_reservations: ::Reservation.pending.count,
              pending_reviews: ::Review.pending.count
            },
            overdue_books: overdue_books_data,
            pending_reviews: pending_reviews_data,
            recent_borrowings: recent_borrowings_data,
            pending_reservations: pending_reservations_data
          }
        end

        private

        def overdue_books_data
          ::Borrowing.overdue
                     .includes(:member, :book)
                     .limit(10)
                     .map do |b|
            {
              id: b.id,
              member: { id: b.member.id, name: b.member.name },
              book: { id: b.book.id, title: b.book.title },
              due_date: b.due_date,
              days_overdue: b.days_overdue
            }
          end
        end

        def pending_reviews_data
          ::Review.pending
                  .includes(:reviewer, :reviewable)
                  .order(created_at: :desc)
                  .limit(20)
                  .map do |r|
            {
              id: r.id,
              reviewer: { id: r.reviewer.id, name: r.reviewer.name },
              reviewable_id: r.reviewable_id,
              reviewable_type: r.reviewable_type,
              reviewable_title: r.reviewable.try(:title) || r.reviewable.try(:name),
              rating: r.rating,
              comment: r.comment,
              created_at: r.created_at
            }
          end
        end

        def recent_borrowings_data
          ::Borrowing.includes(:member, :book)
                     .order(created_at: :desc)
                     .limit(10)
                     .map do |b|
            {
              id: b.id,
              member: { id: b.member.id, name: b.member.name },
              book: { id: b.book.id, title: b.book.title },
              created_at: b.created_at,
              status: b.status
            }
          end
        end

        def pending_reservations_data
          ::Reservation.pending
                       .includes(:member, :book)
                       .order(created_at: :desc)
                       .map do |r|
            {
              id: r.id,
              member: { id: r.member.id, name: r.member.name },
              book: { id: r.book.id, title: r.book.title },
              created_at: r.created_at
            }
          end
        end
      end
    end
  end
end