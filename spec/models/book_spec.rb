require 'rails_helper'

RSpec.describe Book, type: :model do
  

  subject { build(:book) }

  describe 'associations' do
    it { should have_many(:book_authors).dependent(:destroy) }
    it { should have_many(:authors).through(:book_authors) }
    
    it { should have_many(:book_categories).dependent(:destroy) }
    it { should have_many(:categories).through(:book_categories) }
    

it { should have_many(:borrowings).dependent(:destroy) }
    it { should have_many(:borrowers).through(:borrowings).source(:member) }
    
    it { should have_many(:reservations).dependent(:destroy) }
    it { should have_many(:reviews) }
    it { should have_and_belong_to_many(:tags) }
  end


  describe 'validations' do
    context 'uniqueness' do
      subject { create(:book, isbn: '978-X-12345') }
      it { should validate_uniqueness_of(:isbn).case_insensitive.allow_blank }
    end

    it { should validate_presence_of(:title) }
    it { should validate_numericality_of(:total_copies).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:available_copies).is_greater_than_or_equal_to(0) }
  end


  describe 'scopes' do
    let!(:available_book) { create(:book, available_copies: 3) }
    let!(:unavailable_book) { create(:book, available_copies: 0) }

    describe '.available' do
      it 'returns books with available copies > 0' do
        expect(Book.available).to include(available_book)
        expect(Book.available).not_to include(unavailable_book)
      end
    end

    describe '.unavailable' do
      it 'returns books with 0 available copies' do
        expect(Book.unavailable).to include(unavailable_book)
        expect(Book.unavailable).not_to include(available_book)
      end
    end
    
    describe '.search' do
      let!(:gatsby) { create(:book, title: 'The Great Gatsby', isbn: '9780743273565') }
      let!(:mockingbird) { create(:book, title: 'To Kill a Mockingbird', isbn: '9780061120084') }

      it 'finds books by title (case insensitive)' do
        results = Book.search('gatsby')
        expect(results).to include(gatsby)
        expect(results).not_to include(mockingbird)
      end

      it 'finds books by ISBN' do
        results = Book.search('9780743273565')
        expect(results).to include(gatsby)
        expect(results).not_to include(mockingbird)
      end
    end

    describe '.by_category' do
      let(:category) { create(:category) }
      let(:book_in_cat) { create(:book) }
      let(:book_out_cat) { create(:book) }

      before { book_in_cat.categories << category }

      it 'filters books by category id' do
        results = Book.by_category(category.id)
        expect(results).to include(book_in_cat)
        expect(results).not_to include(book_out_cat)
      end
    end
  end

  describe 'instance methods' do
    describe '#available?' do
      it 'returns true when available_copies > 0' do
        book = build(:book, available_copies: 1)
        expect(book.available?).to be true
      end

      it 'returns false when available_copies = 0' do
        book = build(:book, available_copies: 0)
        expect(book.available?).to be false
      end
    end

    describe '#decrement_available_copies!' do
      it 'decrements available_copies by 1' do
        book = create(:book, available_copies: 5)
        expect { book.decrement_available_copies! }.to change { book.reload.available_copies }.by(-1)
      end

      it 'does not decrement below 0' do
        book = create(:book, available_copies: 0)
        book.decrement_available_copies!
        expect(book.reload.available_copies).to eq(0)
      end
    end

    describe '#increment_available_copies!' do
      it 'increments available_copies by 1' do
        book = create(:book, available_copies: 3, total_copies: 5)
        expect { book.increment_available_copies! }.to change { book.reload.available_copies }.by(1)
      end

      it 'does not increment above total_copies' do
        book = create(:book, available_copies: 5, total_copies: 5)
        book.increment_available_copies!
        expect(book.reload.available_copies).to eq(5)
      end
    end

    describe '#update_average_rating! (persistence)' do
      let(:book) { create(:book) }
      let(:member) { create(:member) }

      before do
        create(:review, reviewable: book, rating: 5, status: :approved, reviewer: member)
        create(:review, reviewable: book, rating: 3, status: :approved, reviewer: create(:member))
        create(:review, reviewable: book, rating: 1, status: :pending, reviewer: create(:member))
      end

      it 'persists average rating from approved reviews only' do
        book.update_average_rating!
        expect(book.reload.average_rating).to eq(4.0) 
      end

      it 'sets 0.0 if no approved reviews exist' do
        book.reviews.destroy_all
        book.update_average_rating!
        expect(book.reload.average_rating).to eq(0.0)
      end
    end
  end

  describe 'callbacks' do
    describe '#normalize_isbn' do
      it 'removes non-alphanumeric characters from ISBN before validation' do
        book = create(:book, isbn: '978-0-12345-678-9')
        expect(book.reload.isbn).to eq('9780123456789')
      end
    end

    describe '#set_initial_copies' do
      it 'sets available_copies equal to total_copies on create if not provided' do
        book = Book.create(title: 'Test', total_copies: 10, isbn: '999-X-99999', available_copies: nil)
        expect(book.available_copies).to eq(10)
      end
    end

    describe '#check_active_borrowings (before_destroy)' do
      let!(:book) { create(:book) }

      it 'allows destruction if there are no borrowings' do
        expect { book.destroy }.to change(Book, :count).by(-1)
      end

      it 'allows destruction if borrowings are returned' do
        create(:borrowing, :returned, book: book)
        expect { book.destroy }.to change(Book, :count).by(-1)
      end

      it 'prevents destruction if active borrowings exist', :aggregate_failures do
        create(:borrowing, :active, book: book)
        expect { book.destroy }.not_to change(Book, :count)
        expect(book.errors[:base]).to include("Cannot delete book with active borrowings")
        expect(book.destroyed?).to be false
      end
    end
  end

  describe 'ransackable attributes' do
    it 'whitelists specific attributes' do
      expect(Book.ransackable_attributes).to include('title', 'isbn', 'publication_year', 'available_copies')
    end

    it 'whitelists specific associations' do
      expect(Book.ransackable_associations).to include('authors', 'categories', 'reviews', 'borrowings')
    end
  end
end