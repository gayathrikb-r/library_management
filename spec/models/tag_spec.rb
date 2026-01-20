require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'validations' do
    subject { build(:tag) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe 'associations' do
    it { should have_and_belong_to_many(:books) }
  end

  describe 'class methods' do

    describe '.ransackable_attributes' do
      it 'whitelists specific attributes for search' do
        expect(Tag.ransackable_attributes).to match_array(%w[id name created_at updated_at])
      end
    end
  end

  describe 'instance methods' do
    describe '#books_count' do
      let(:tag) { create(:tag) }
      
      it 'returns the number of associated books' do
        create_list(:book, 2, tags: [tag])
        expect(tag.books_count).to eq(2)
      end

      it 'returns 0 if no books are associated' do
        expect(tag.books_count).to eq(0)
      end
    end
  end
end