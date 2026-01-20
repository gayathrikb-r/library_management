require 'rails_helper'

RSpec.describe BookCategory, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:book_category)).to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:book) }
    it { should belong_to(:category) }
  end

  describe 'validations' do
   
    subject { create(:book_category) } 
    
    it { should validate_uniqueness_of(:book_id).scoped_to(:category_id) }
  end

  describe 'ransackable configuration' do

    describe '.ransackable_attributes' do
      it 'whitelists allowed attributes' do
        expected_attributes = %w[id book_id category_id created_at updated_at]
        expect(BookCategory.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'whitelists allowed associations' do
        expect(BookCategory.ransackable_associations).to eq([])
      end
    end
  end
end