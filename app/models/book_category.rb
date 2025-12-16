class BookCategory < ApplicationRecord
  belongs_to :book
  belongs_to :category
  validates :book_id, uniqueness: { scope: :author_id }
end
