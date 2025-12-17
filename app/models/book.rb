class Book < ApplicationRecord
  has_many :book_authors, dependent: :destroy
  has_many :book_categories, dependent: :destroy
  has_many :authors, through: :book_authors
  has_many :categories, through: :book_categories
  has_many :borrowings, dependent: :restrict_with_error#cant delete book with active borrowings
  has_many :borrowers, through: :borrowings, source: :user
  has_many :reservations, dependent: :destroy
  has_many :reviews, as: :reviewable, dependent: :destroy
  has_and_belongs_to_many :tags

  #Validations
  validates :title, presence: true
  validates :isbn, uniqueness: true, allow_blank: true
  validates :total_copies, :available_copies, numericality: { greater_than_or_equal_to: 0 }
  validate :available_copies_cannot_exceed_total

  #Callbacks
  before_validation :normalize_isbn
  before_validation :set_initial_copies, on: :create
  before_destroy :check_active_borrowings
  #Scopes
  scope :available, -> { where("available_copies > 0") }
  scope :unavailable, -> { where(available_copies: 0) }
  scope :popular, -> { order(reviews_count: :desc) }
  scope :highest_rated, -> { where.not(average_rating: nil).order(reviews_count: :desc)}

  def available?
    available_copies>0
  end
  def decrement_available_copies!
    return unless available?
    decrement!(:available_copies)
  end
  def increment_available_copies!
    return if available_copies>=total_copies
    increment!(:available_copies)
  end
  def update_average_rating!
    approved_reviews = reviews.where(status: "approved")
    update!(
      average_rating: approved_reviews.average(:rating),
      reviews_count: approved_reviews.count
    )
  end
  private
 
  def normalize_isbn
    return if isbn.blank?
    self.isbn = isbn.gsub(/[^0-9X]/i, "").upcase#isbn can be numbers and can end with X
    #upcase it and save to book
  end
  def set_initial_copies
    self.available_copies ||= total_copies
  end
  def available_copies_cannot_exceed_total
    if available_copies && total_copies && available_copies > total_copies
      errors.add(:available_copies, "cannot exceed total copies")
    end
  end
  
  def check_active_borrowings
    if borrowings.where(status: 'active').exists?
      errors.add(:base, "Cannot delete book with active borrowings")
      throw :abort
    end
  end


end
