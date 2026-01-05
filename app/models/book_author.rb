class BookAuthor < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    [
      "id",
      "book_id",
      "author_id",
      "created_at",
      "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
  belongs_to :book
  belongs_to :author
end
