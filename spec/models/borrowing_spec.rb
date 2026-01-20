require 'rails_helper'

RSpec.describe Borrowing, type: :model do
 
  subject { build(:borrowing) }

  describe 'associations' do
    it { should belong_to(:member) }
    it { should belong_to(:book) }
    it { should belong_to(:librarian).optional }
  end

  describe 'validations' do
    it 'sets default dates on creation' do
      borrowing = Borrowing.create(member: create(:member), book: create(:book))
      
      aggregate_failures "default dates" do
        expect(borrowing.borrowed_date).to eq(Date.today)
        expect(borrowing.due_date).to be_present
      end
    end

    context 'custom date validation' do
      it 'is valid when due_date is after borrowed_date' do
        borrowing = build(:borrowing, borrowed_date: Date.today, due_date: Date.tomorrow)
        expect(borrowing).to be_valid
      end

      it 'is invalid when due_date is before borrowed_date' do
        borrowing = build(:borrowing, borrowed_date: Date.today, due_date: Date.yesterday)
        
        aggregate_failures do
          expect(borrowing).not_to be_valid
          expect(borrowing.errors[:due_date]).to include("must be after borrowed date")
        end
      end
    end

    context 'member restrictions' do
      let(:member) { create(:member) }
      
      it 'prevents borrowing if member has reached limit (5)' do
        create_list(:borrowing, 5, member: member)
        new_borrowing = build(:borrowing, member: member)
        
        aggregate_failures do
          expect(new_borrowing).not_to be_valid
          expect(new_borrowing.errors[:base]).to include("Borrowing limit reached")
        end
      end

      it 'allows borrowing beyond limit if created by librarian' do
        create_list(:borrowing, 5, member: member)
        new_borrowing = build(:borrowing, member: member, created_by_librarian: true)
        expect(new_borrowing).to be_valid
      end

      it 'prevents borrowing if member has overdue books' do
        create(:borrowing, :overdue, member: member)
        new_borrowing = build(:borrowing, member: member)
        
        aggregate_failures do
          expect(new_borrowing).not_to be_valid
          expect(new_borrowing.errors[:base]).to include("Member has overdue books")
        end
      end
    end

    context 'book availability' do
      let(:book) { create(:book, available_copies: 0) }
      let(:member) { create(:member) }

      it 'prevents borrowing if book is unavailable and no reservation exists' do
        borrowing = build(:borrowing, book: book, member: member)
        
        aggregate_failures do
          expect(borrowing).not_to be_valid
          expect(borrowing.errors[:base]).to include("Book is not available")
        end
      end
      
      it 'allows borrowing if member has a pending reservation' do
        create(:reservation, book: book, member: member, status: :pending)
        borrowing = build(:borrowing, book: book, member: member)
        expect(borrowing).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:active)   { create(:borrowing, returned_date: nil, due_date: 1.week.from_now, status: :borrowed) }
    let!(:returned) { create(:borrowing, :returned) }
    let!(:overdue)  { create(:borrowing, :overdue) }
    let!(:due_soon) { create(:borrowing, status: :borrowed, due_date: 2.days.from_now) }

    it 'active: returns non-returned borrowings with future due dates' do
      aggregate_failures "active scope" do
        expect(Borrowing.active).to include(active)
        expect(Borrowing.active).not_to include(returned)
        expect(Borrowing.active).not_to include(overdue)
      end
    end

    it 'overdue: returns overdue borrowings' do
      aggregate_failures "overdue scope" do
        expect(Borrowing.overdue).to include(overdue)
        expect(Borrowing.overdue).not_to include(active)
      end
    end

    it 'borrowed: returns borrowings with status borrowed' do
      aggregate_failures "borrowed scope" do
        expect(Borrowing.borrowed).to include(active)
        expect(Borrowing.borrowed).not_to include(returned)
      end
    end

    it 'returned: returns returned borrowings' do
      aggregate_failures "returned scope" do
        expect(Borrowing.returned).to include(returned)
        expect(Borrowing.returned).not_to include(active)
      end
    end

    it 'due_soon: returns borrowings due within 3 days' do
      aggregate_failures "due_soon scope" do
        expect(Borrowing.due_soon).to include(due_soon)
        expect(Borrowing.due_soon).not_to include(active)
      end
    end
  end

  describe '#days_overdue' do
    it 'returns 0 for active borrowings' do
      borrowing = build(:borrowing, :active)
      expect(borrowing.days_overdue).to eq(0)
    end

    it 'calculates days overdue correctly' do
      borrowing = build(:borrowing, :overdue, borrowed_date: 10.days.ago, due_date: 5.days.ago)
      expect(borrowing.days_overdue).to eq(5)
    end
  end

  describe '#calculate_fine' do
    it 'calculates fine based on days overdue (5 per day)' do
      borrowing = build(:borrowing, :overdue, borrowed_date: 10.days.ago, due_date: 4.days.ago)
      expect(borrowing.calculate_fine).to eq(20)
    end
  end

  describe '#mark_as_returned!' do
    let(:book) { create(:book, available_copies: 1, total_copies: 5) }
    let!(:borrowing) do 
      create(:borrowing, book: book, status: :borrowed, borrowed_date: Date.today, returned_date: nil)
    end

    it 'increments book available_copies' do
      expect(book.reload.available_copies).to eq(0)
      expect { borrowing.mark_as_returned! }.to change { book.reload.available_copies }.by(1)
    end

    it 'updates status to returned and returned_date to today' do
      borrowing.mark_as_returned!
      
      aggregate_failures "updates state" do
        expect(borrowing.reload.status).to eq('returned')
        expect(borrowing.reload.returned_date).to eq(Date.today)
      end
    end

    it 'returns nil if already returned' do
      borrowing.mark_as_returned!
      expect(borrowing.mark_as_returned!).to be_nil
    end

    it 'returns false and logs error if transaction fails' do
      allow(borrowing).to receive(:update!).and_raise(StandardError, "DB Error")
      expect(Rails.logger).to receive(:error).with(/Error marking borrowing as returned/)
      expect(borrowing.mark_as_returned!).to be false
    end
  end

  describe '#increase_book_availability (private)' do
    it 'increments the book available copies' do
      book = create(:book, available_copies: 5)
      borrowing = create(:borrowing, book: book)
      
      expect { 
        borrowing.send(:increase_book_availability) 
      }.to change { book.reload.available_copies }.by(1)
    end
  end

  describe '#as_json' do
    it 'includes custom fields' do
      borrowing = create(:borrowing, :overdue, borrowed_date: 10.days.ago, due_date: 2.days.ago)
      json = borrowing.as_json.stringify_keys
      
      aggregate_failures "json structure" do
        expect(json).to include('active', 'days_overdue', 'fine')
        expect(json['fine']).to eq(10)
      end
    end
  end

  describe 'callbacks' do
    describe 'decrease_book_availability' do
      it 'decrements book available_copies on create' do
        book = create(:book, available_copies: 5)
        expect { create(:borrowing, book: book) }.to change { book.reload.available_copies }.by(-1)
      end
    end

    describe 'check_if_overdue' do
      it 'updates status to overdue if due date has passed' do
     
        borrowing = create(:borrowing, 
                           status: :borrowed, 
                           borrowed_date: 5.days.ago, 
                           due_date: 1.day.ago)
        
        borrowing.valid? 
        expect(borrowing.status).to eq('overdue')
      end
    end

    describe 'notify_next_reservation' do
      it 'fulfills the next pending reservation when book is returned' do
        book = create(:book)
        borrowing = create(:borrowing, book: book)
        reservation = create(:reservation, book: book, status: :pending)

        borrowing.update(status: :returned, returned_date: Date.today)
        
        expect(reservation.reload.status).to eq('fulfilled')
      end
    end
  end

  describe 'ransackable attributes' do
    it 'whitelists attributes and associations' do
      aggregate_failures do
        expect(Borrowing.ransackable_attributes).to include("book_id", "status", "due_date")
        expect(Borrowing.ransackable_associations).to include("book", "member", "librarian")
      end
    end
  end
end