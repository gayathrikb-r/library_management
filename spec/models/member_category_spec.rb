require 'rails_helper'

RSpec.describe MemberCategory, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:member_category)).to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:member) }
    it { should belong_to(:category) }
  end

  describe 'ransackable configuration' do
    describe '.ransackable_attributes' do
      it 'whitelists specific attributes' do
        expected = %w[id member_id category_id created_at updated_at]
        expect(MemberCategory.ransackable_attributes).to match_array(expected)
      end
    end

    describe '.ransackable_associations' do
      it 'whitelists specific associations' do
        expected = %w[member category]
        expect(MemberCategory.ransackable_associations).to match_array(expected)
      end
    end
  end
end