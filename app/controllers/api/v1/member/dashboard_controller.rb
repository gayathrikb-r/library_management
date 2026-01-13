module Api
  module V1
    module Member
      class DashboardController < BaseController
        before_action :authenticate_member!

        def show
          borrowings = current_member.borrowings
                                     .where(status: ['borrowed', 'overdue'])
                                     .includes(:book)
                                     .order(due_date: :asc)

          reservations = current_member.reservations
                                       .where(status: 'pending')
                                       .includes(:book)
                                       .order(created_at: :desc)

          recent_reviews = current_member.reviews
                                         .includes(:reviewable)
                                         .order(created_at: :desc)
                                         .limit(5)

          render json: {
            borrowings: borrowings.as_json(
              include: { book: { only: [:id, :title] } },
              methods: [:days_overdue]
            ),
            reservations: reservations.as_json(
              include: { book: { only: [:id, :title] } }
            ),
            recent_reviews: recent_reviews.map do |review|
              {
                id: review.id,
                rating: review.rating,
                comment: review.comment,
                status: review.status,
                created_at: review.created_at,
                reviewable_id: review.reviewable_id,
                reviewable_type: review.reviewable_type,
                reviewable_title: review.reviewable.try(:title) || review.reviewable.try(:name)
              }
            end
          }
        end
      end
    end
  end
end