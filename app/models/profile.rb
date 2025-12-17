class Profile < ApplicationRecord
  belongs_to :user
  belongs_to :favorite_author, class_name: 'Author',optional: true
  validates :user_id, uniqueness: true
  before_validation :format_liked_genres
  private
  def format_liked_genres
    return if liked_genres.blank?
    self.liked_genres=liked_genres.split(',').map(&:strip).join(', ')
  end
end
