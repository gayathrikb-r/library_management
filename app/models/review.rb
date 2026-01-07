class Review < ApplicationRecord
  belongs_to :reviewer, polymorphic: true
  belongs_to :reviewable, polymorphic: true
  def self.ransackable_associations(auth_object = nil)
    ["reviewable", "reviewer"]
  end
  def self.ransackable_attributes(auth_object = nil)
    ["comment", "created_at", "id", "id_value", "rating", "reviewable_id", "reviewable_type", "reviewer_id", "reviewer_type", "status", "updated_at"]
  end
  enum status: { pending: 0, approved: 1, flagged: 2 }

  validates :rating, inclusion: { in: 1..5 }
  validates :comment, length: { minimum: 10, maximum: 1000 }

  validates :reviewer_id,
            uniqueness: {
              scope: %i[reviewer_type reviewable_id reviewable_type],
              message: "has already reviewed this item"
            }

  before_validation :strip_comment
  after_save :update_reviewable_rating, if: :saved_change_to_rating_or_status?
  after_destroy :update_reviewable_rating

  scope :recent, -> { order(created_at: :desc) }
  scope :pending_first, -> { order(status: :asc, created_at: :desc) }
  def approve!
    approved!
  end

  def flag!
    flagged!
  end

  private

  def strip_comment
    self.comment = comment.strip if comment.present?
  end

  def saved_change_to_rating_or_status?
    saved_change_to_rating? || saved_change_to_status?
  end

  def update_reviewable_rating
    reviewable.update_average_rating! if reviewable.respond_to?(:update_average_rating!)
  end
end
