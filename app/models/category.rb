class Category < ApplicationRecord
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      name
      created_at
      updated_at
    ]
  end
  has_many :book_categories, dependent: :destroy
  has_many :member_categories, dependent: :destroy
  has_many :members, through: :member_categories
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
