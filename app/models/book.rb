class Book < ApplicationRecord
  has_many :book_authors, dependent: :destroy
  has_many :authors, through: :book_authors

  has_many :book_categories, dependent: :destroy
  has_many :categories, through: :book_categories

  has_many :borrowings, dependent: :restrict_with_error
  has_many :borrowers, through: :borrowings, source: :member

  has_many :reservations, dependent: :destroy
  has_many :reviews, as: :reviewable, dependent: :destroy

  has_and_belongs_to_many :tags

  # Validations
  validates :title, presence: true
  validates :isbn, uniqueness: true, allow_blank: true
  validates :total_copies, :available_copies,
            numericality: { greater_than_or_equal_to: 0 }
  validate :available_copies_cannot_exceed_total

  # Callbacks
  before_validation :normalize_isbn
  before_validation :set_initial_copies, on: :create
  before_destroy :check_active_borrowings

  # Scopes
  scope :available, -> { where("available_copies > 0") }
  scope :unavailable, -> { where(available_copies: 0) }
  scope :popular, -> { order(reviews_count: :desc) }
  scope :highest_rated, -> { where.not(average_rating: nil).order(average_rating: :desc) }
  scope :search, ->(term) {
    where("title ILIKE :term OR isbn ILIKE :term", term: "%#{term}%") if term.present?
  }
  scope :by_category, ->(category_id) {
    joins(:categories).where(categories: { id: category_id }) if category_id.present?
  }

  # Instance methods
  def available?
    available_copies.positive?
  end

  def decrement_available_copies!
    decrement!(:available_copies) if available?
  end

  def increment_available_copies!
    increment!(:available_copies) if available_copies < total_copies
  end

  def update_average_rating!
    approved = reviews.approved
    update!(
      average_rating: approved.average(:rating),
      reviews_count: approved.count
    )
  end

  private

  def normalize_isbn
    self.isbn = isbn.present? ? isbn.gsub(/[^0-9X]/i, "").upcase : nil
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
    if borrowings.borrowed.exists?
      errors.add(:base, "Cannot delete book with active borrowings")
      throw :abort
    end
  end
end
