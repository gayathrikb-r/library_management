class MemberCategory < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    %w[id member_id category_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[member category]
  end
  belongs_to :member
  belongs_to :category
end
