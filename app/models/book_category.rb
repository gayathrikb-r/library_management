class BookCategory < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    %w[
      id
      book_id
      category_id
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
  belongs_to :book
  belongs_to :category
  validates :book_id, uniqueness: { scope: :category_id }
end
