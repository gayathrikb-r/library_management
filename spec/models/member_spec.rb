require 'rails_helper'

RSpec.describe Member, type: :model do

  subject { build(:member) }


  describe 'associations' do

    it { should have_many(:oauth_access_grants).dependent(:destroy).class_name('Doorkeeper::AccessGrant') }
    it { should have_many(:oauth_access_tokens).dependent(:destroy).class_name('Doorkeeper::AccessToken') }


    it { should have_many(:borrowings).dependent(:restrict_with_error) }
    it { should have_many(:reservations).dependent(:destroy) }
    
        it { should have_many(:reviews).dependent(:destroy) }


    it { should have_many(:borrowed_books).through(:borrowings).source(:book) }
    it { should have_many(:reserved_books).through(:reservations).source(:book) }


    it { should have_many(:member_categories).dependent(:destroy) }
    it { should have_many(:liked_categories).through(:member_categories).source(:category) }
    
    
    it { should belong_to(:favorite_author).class_name('Author').optional }
  end
  describe 'validations' do

    subject { create(:member) } 

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:name) }
    
    context 'phone format' do
      it { should allow_value('1234567890').for(:phone) }
      it { should allow_value(nil).for(:phone) }
      it { should_not allow_value('123-456-7890').for(:phone).with_message('must be 10 digits') }
      it { should_not allow_value('abcdefghij').for(:phone) }
      it { should_not allow_value('123').for(:phone) }
    end
  end

  describe 'callbacks' do
    describe '#normalize_phone' do
      it 'strips non-numeric characters before validation' do
        member = build(:member, phone: '(555) 123-4567')
        member.valid? 
        expect(member.phone).to eq('5551234567')
      end
    end

    describe 'before_destroy :check_active_borrowings' do
      let!(:member) { create(:member) }

      context 'when member has active borrowings' do
        before do
          create(:borrowing, member: member, returned_at: nil)
        end

        it 'does not destroy the member' do
          expect { member.destroy }.not_to change(Member, :count)
        end

        it 'adds an error to base' do
          member.destroy
          expect(member.errors[:base]).to include("Cannot delete member with active borrowings")
        end
      end

      context 'when member has NO active borrowings' do
        it 'successfully destroys the member' do
          expect { member.destroy }.to change(Member, :count).by(-1)
        end
      end
    end
  end

  describe 'instance methods' do
    let(:member) { create(:member) }

    describe '#has_overdue_books?' do
      context 'with overdue borrowings' do
        before do 
         
          create(:borrowing, member: member, due_date: 1.day.ago, returned_at: nil) 
        end
        
        it 'returns true' do
          expect(member.has_overdue_books?).to be true
        end
      end

      context 'without overdue borrowings' do
        before do 
       
          create(:borrowing, member: member, due_date: 1.day.from_now, returned_at: nil)
        end

        it 'returns false' do
          expect(member.has_overdue_books?).to be false
        end
      end
    end

    describe '#active_borrowings_count' do
      it 'counts only unreturned borrowings' do
        create_list(:borrowing, 2, member: member, returned_at: nil) # 2 active
        create(:borrowing, member: member, returned_at: Date.today)  # 1 returned
        
        expect(member.active_borrowings_count).to eq(2)
      end
    end
  end

  describe 'ransackable attributes' do
    it 'whitelists specific attributes' do
      expect(Member.ransackable_attributes).to include('name', 'email', 'phone')
    end
    
    it 'whitelists specific associations' do
      expect(Member.ransackable_associations).to include('borrowings', 'reservations', 'reviews')
    end
  end
end