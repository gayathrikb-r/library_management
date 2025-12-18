class Profile < ApplicationRecord
  belongs_to :user
  belongs_to :favorite_author, class_name: 'Author',optional: true
  validates :user_id, uniqueness: true
  validate :liked_genres_must_be_valid_categories
  before_validation :ensure_liked_genres_is_array
  private
  def ensure_liked_genres_is_array
    self.liked_genres = [] if liked_genres.nil?
    self.liked_genres = liked_genres.reject(&:blank?) if liked_genres.is_a?(Array)
  end
  def liked_genres_must_be_valid_categories
    return if liked_genres.blank?
    valid_categories=Category.pluck(:name)
    invalid_genres=liked_genres-valid_categories
    if invalid_genres.any?
      errors.add(:liked_genres, "contains invalid categories: #{invalid_genres.join(', ')}")
    end
    if liked_genres.size!=liked_genres.uniq.size
      errors.add(:liked_genres, "contains duplicate entries")
    end
    # Limit to 5 genres max
    if liked_genres.size > 5
      errors.add(:liked_genres, "maximum 5 genres allowed")
    end
  end
end
