require 'rails_helper'

RSpec.describe Author, type: :model do
  subject { build(:author) }

  
  describe 'associations' do
    
    it { should have_many(:book_authors).dependent(:destroy) }
    it { should have_many(:books).through(:book_authors) }
    
   
    it { should have_many(:reviews).dependent(:destroy) }
    
    
    it { 
      should have_many(:members)
        .with_foreign_key('favorite_author_id')
        .dependent(:nullify) 
    }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'scopes' do
    describe '.search_by_name' do
      let!(:tolkien) { create(:author, name: 'J.R.R. Tolkien') }
      let!(:rowling) { create(:author, name: 'J.K. Rowling') }

      it 'returns authors matching the query case-insensitively' do
        expect(Author.search_by_name('tolkien')).to include(tolkien)
        expect(Author.search_by_name('tolkien')).not_to include(rowling)
      end

      it 'returns partial matches' do
        expect(Author.search_by_name('Row')).to include(rowling)
      end
    end
  end

  describe 'instance methods' do
    describe '#books_count' do
      let(:author) { create(:author) }

      it 'returns the correct count of associated books' do
        create_list(:book, 3, authors: [author])
        expect(author.books_count).to eq(3)
      end

      it 'returns 0 when there are no books' do
        expect(author.books_count).to eq(0)
      end
    end

    describe '#as_json' do
      let(:author) { create(:author) }

      it 'includes books_count in the JSON output' do
        create_list(:book, 2, authors: [author])
        
        json = author.as_json
        expect(json).to have_key('books_count')
        expect(json['books_count']).to eq(2)
      end
    end
  end

  describe 'ransackable attributes' do
    it 'whitelists specific attributes' do
      expect(Author.ransackable_attributes).to match_array(%w[id name created_at updated_at])
    end

    it 'whitelists specific associations' do
      expect(Author.ransackable_associations).to match_array(%w[books])
    end
  end
end