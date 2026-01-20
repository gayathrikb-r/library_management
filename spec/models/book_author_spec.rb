require 'rails_helper'

RSpec.describe BookAuthor, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:book_author)).to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:book) }
    it { should belong_to(:author) }
  end

  describe 'ransackable configuration' do
    describe '.ransackable_attributes' do
      it 'returns the allowed attributes' do
        expected = ["id", "book_id", "author_id", "created_at", "updated_at"]
        expect(BookAuthor.ransackable_attributes).to match_array(expected)
      end
    end

    describe '.ransackable_associations' do
      it 'returns an empty array' do
        expect(BookAuthor.ransackable_associations).to eq([])
      end
    end
  end
end