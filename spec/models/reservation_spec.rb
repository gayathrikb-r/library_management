require 'rails_helper'

RSpec.describe Reservation, type: :model do
  # Pre-create member/book to control when logs happen and ensure valid associations
  let(:member) { create(:member) } 
  let(:book) { create(:book, available_copies: 0) }

  subject { build(:reservation, member: member, book: book) }

  describe 'associations' do
    it { should belong_to(:member) }
    it { should belong_to(:book) }
  end

  describe 'validations' do
    it { should validate_presence_of(:book_id) }
    it { should validate_presence_of(:member_id) }

    # Because set_defaults populates these on :create, we test presence on :update 
    # to ensure the validation line is covered without callback interference.
    context 'on update' do
      subject { create(:reservation, member: member, book: book, skip_availability_check: true) }
      it { should validate_presence_of(:reservation_date).on(:update) }
      it { should validate_presence_of(:status).on(:update) }
    end

    describe 'custom validations' do
      describe '#book_must_be_unavailable' do
        let(:available_book) { create(:book, available_copies: 1) }

        it 'adds error if book is available' do
          reservation = build(:reservation, book: available_book, member: member)
          expect(reservation).not_to be_valid
          expect(reservation.errors[:base]).to include("Book is currently available and does not need reservation")
        end

        it 'is valid if book is unavailable' do
          unavailable_book = create(:book, available_copies: 0)
          reservation = build(:reservation, book: unavailable_book, member: member)
          expect(reservation).to be_valid
        end

        it 'skips validation if skip_availability_check is true' do
          reservation = build(:reservation, book: available_book, member: member, skip_availability_check: true)
          expect(reservation).to be_valid
        end
      end

      describe '#no_duplicate_pending_reservation' do
        it 'prevents duplicate pending reservations' do
          create(:reservation, book: book, member: member, status: :pending, skip_availability_check: true)

          duplicate = build(:reservation, book: book, member: member, status: :pending)
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("You already have a pending reservation for this book")
        end
      end
    end
  end

  describe 'callbacks' do
    describe 'set_defaults' do
      it 'sets default status and date on create' do
        reservation = Reservation.new(book: book, member: member, skip_availability_check: true)
        reservation.save
        
        aggregate_failures do
          expect(reservation.status).to eq('pending')
          expect(reservation.reservation_date).to eq(Date.current)
        end
      end
    end

    describe 'send_confirmation' do
      it 'logs confirmation email on create' do
        # We create a new member inside this test to trigger the welcome log first, 
        # then we expect the reservation log.
        new_member = create(:member) 
        
        expect(Rails.logger).to receive(:info).with(/Reservation confirmation sent to/)
        create(:reservation, member: new_member, book: book, skip_availability_check: true)
      end
    end
  end

  describe 'instance methods' do
    describe '#fulfill!' do
      # We use skip_availability_check to create a pending reservation regardless of book state
      let!(:reservation) { create(:reservation, book: book, member: member, status: :pending, skip_availability_check: true) }

      context 'when successful' do
        before { book.update(available_copies: 1) } # Make book available now

        it 'creates borrowing, updates status, and logs info' do
          expect(Rails.logger).to receive(:info).with(/Reservation .* fulfilled/)

          expect { reservation.fulfill! }.to change(Borrowing, :count).by(1)
          
          aggregate_failures do
            expect(reservation.reload.status).to eq('fulfilled')
            expect(book.reload.available_copies).to eq(0)
          end
        end
      end

      context 'when book has no copies' do
        before { book.update(available_copies: 0) }

        it 'fails and adds error' do
          result = reservation.fulfill!
          
          aggregate_failures do
            expect(result).to be_falsey
            expect(reservation.errors[:base]).to include("No available copies to fulfill reservation")
            expect(reservation.reload.status).to eq('pending')
          end
        end
      end
context 'when borrowing creation fails' do
        before { book.update(available_copies: 1) }

        it 'rescues error and returns false' do
          borrowings_proxy = double("BorrowingsProxy")
          
          allow(reservation.book).to receive(:borrowings).and_return(borrowings_proxy)
          
          allow(borrowings_proxy).to receive(:create!)
            .and_raise(ActiveRecord::RecordInvalid.new(Borrowing.new))
          
          expect(reservation.fulfill!).to be false
          expect(reservation.errors[:base]).not_to be_empty
        end
      end
      context 'when not pending' do
        it 'returns false' do
          reservation.update(status: :cancelled)
          expect(reservation.fulfill!).to be false
        end
      end
    end

    describe '#cancel!' do
      let!(:reservation) { create(:reservation, book: book, member: member, status: :pending, skip_availability_check: true) }

      it 'cancels reservation and logs' do
        expect(Rails.logger).to receive(:info).with(/Reservation #{reservation.id} cancelled/)
        
        expect(reservation.cancel!).to be true
        expect(reservation.reload.status).to eq('cancelled')
      end

      it 'fails if not pending' do
        reservation.update(status: :fulfilled)
        expect(reservation.cancel!).to be false
      end

       context 'when update fails' do
        it 'rescues RecordInvalid and returns false' do
          allow(reservation).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(reservation))
          
          expect(reservation.cancel!).to be false
          expect(reservation.errors[:base]).not_to be_empty
        end
      end
    end

    describe '#as_json' do
       let!(:reservation) { create(:reservation, book: book, member: member, skip_availability_check: true) }
       
       it 'includes custom fields' do
         json = reservation.as_json.stringify_keys
         
         aggregate_failures do
           expect(json['status_label']).to eq('Pending')
           expect(json['book_title']).to eq(book.title)
           expect(json['member_name']).to eq(member.name)
         end
       end
    end
  end
end