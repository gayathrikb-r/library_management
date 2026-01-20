require 'rails_helper'

RSpec.describe Category, type: :model do

  subject { build(:category) }

  
  describe 'associations' do
    # Books
    it { should have_many(:book_categories).dependent(:destroy) }
    it { should have_many(:books).through(:book_categories) }
    
    # Members
    it { should have_many(:member_categories).dependent(:destroy) }
    it { should have_many(:members).through(:member_categories) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }


    context 'uniqueness' do
      let!(:existing_category) { create(:category, name: 'Science Fiction') }

     it 'validates uniqueness case-insensitively' do
    
        duplicate = build(:category, name: 'SCIENCE FICTION')
      
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include('has already been taken')
      end
    end
  end


  describe 'callbacks' do
    describe '#normalize_name' do
      it 'strips whitespace and titleizes the name' do
        category = create(:category, name: '  science fiction  ')
        expect(category.name).to eq('Science Fiction')
      end

      it 'handles already correct names' do
        category = create(:category, name: 'Fantasy')
        expect(category.name).to eq('Fantasy')
      end
    end
  end

  describe 'instance methods' do
    describe '#books_count' do
      let(:category) { create(:category) }

      it 'returns the count of associated books' do
        create_list(:book, 5, categories: [category])
        expect(category.books_count).to eq(5)
      end
      
      it 'returns 0 for empty category' do
        expect(category.books_count).to eq(0)
      end
    end

    describe '#as_json' do
      let(:category) { create(:category) }

      it 'includes books_count in the JSON output' do
        create_list(:book, 2, categories: [category])
        
        json = category.as_json
        expect(json).to have_key('books_count')
        expect(json['books_count']).to eq(2)
      end
    end
  end

  describe 'ransackable attributes' do
    it 'whitelists specific attributes' do
      expect(Category.ransackable_attributes).to match_array(%w[id name created_at updated_at])
    end
  end
end