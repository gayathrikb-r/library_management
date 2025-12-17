class Review < ApplicationRecord
  belongs_to :user
  belongs_to :reviewable, polymorphic: true
  STATUSES = %w[pending approved flagged].freeze
  validates :rating, presence: true, inclusion: {in: 1..5}
  validates :comment, presence: true, length: {minimum: 10, maximum: 1000}
  validates :status, inclusion: {in: STATUSES}
  validates :user_id, uniqueness: {scope: [:reviewable_id, :reviewable_type],message: "has already reviewed this item"}
  # Callbacks
  before_validation :strip_comment
  after_save :update_reviewable_rating, if: :saved_change_to_rating_or_status?
  after_destroy :update_reviewable_rating

  # Scopes
  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
  scope :flagged, -> { where(status: 'flagged') }
  def approve!
    update(status: 'approved')
  end
  def flag!
    update(status: 'flagged')
  end
  private
  def strip_comment
    self.comment =comment.strip if comment
  end
  def saved_change_to_rating_or_status?
    saved_change_to_status? || saved_change_to_rating?
  end
  def update_reviewable_rating
    return unless reviewable.respond_to?(:update_average_rating!)
    reviewable.update_average_rating!
  end
  
end
