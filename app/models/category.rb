class Category < ApplicationRecord
  has_many :book_categories, dependent: :destroy
  #if category deleted, join rows in book_categories including that category deleted
  has_many :books, through: :book_categories

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  before_validation :normalize_name

  def books_count
    books.count
  end

  private
  def normalize_name
    return if name.blank?
    self.name = name.strip.titleize
  end
end
