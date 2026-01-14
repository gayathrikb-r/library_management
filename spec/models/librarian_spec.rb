require 'rails_helper'

RSpec.describe Librarian, type: :model do
  
  subject { build(:librarian) }

  describe 'associations' do
    it { should have_many(:processed_borrowings).class_name('Borrowing').dependent(:nullify) }
    
    it { should have_many(:reviews).dependent(:destroy) }

    it { should have_many(:oauth_access_grants).class_name('Doorkeeper::AccessGrant').dependent(:destroy) }
    it { should have_many(:oauth_access_tokens).class_name('Doorkeeper::AccessToken').dependent(:destroy) }
  end

  describe 'validations' do
    before { create(:librarian) }

    it { should validate_presence_of(:name) }
    
    describe 'email' do
      it { should validate_presence_of(:email) }
      it { should validate_uniqueness_of(:email).case_insensitive }
      
      it { should allow_value('test@example.com').for(:email) }
      it { should_not allow_value('testexample.com').for(:email) }
    end

    describe 'phone format' do

      
      it { should allow_value('1234567890').for(:phone) }
      it { should allow_value(nil).for(:phone) } # allow_blank: true
      
      it { should allow_value('123-456-7890').for(:phone) }
      
      it { should_not allow_value('12345').for(:phone).with_message('must be 10 digits') }
      it { should_not allow_value('123456789012').for(:phone).with_message('must be 10 digits') }
    end
  end


  describe 'callbacks' do
    describe '#normalize_phone' do
      it 'strips non-numeric characters before validation' do
        librarian = build(:librarian, phone: '(555) 123-4567')
        librarian.save # Triggers validation and callbacks
        
        expect(librarian.reload.phone).to eq('5551234567')
      end

      it 'ignores nil phone numbers' do
        librarian = build(:librarian, phone: nil)
        librarian.save
        expect(librarian.phone).to be_nil
      end
    end

    describe '#revoke_all_oauth_tokens!' do
      let(:librarian) { create(:librarian) }
      
      let!(:token) do
        Doorkeeper::AccessToken.create!(
          resource_owner_id: librarian.id,
          resource_owner_type: 'Librarian',
          application_id: nil, 
          scopes: 'public',
          expires_in: 2.hours
        )
      end

      context 'when password is changed' do
        it 'revokes existing access tokens' do
          expect(token.revoked_at).to be_nil
          
          librarian.update(password: 'newpass123', password_confirmation: 'newpass123')
          
          expect(token.reload.revoked_at).not_to be_nil
        end
      end

      context 'when name is changed' do
        it 'does NOT revoke access tokens' do
          librarian.update(name: 'New Name')
          expect(token.reload.revoked_at).to be_nil
        end
      end
    end
  end

  describe '.ransackable_attributes' do
    it 'returns the allowed list of attributes' do
      expected_attributes = %w[id name email phone created_at]
      expect(Librarian.ransackable_attributes).to match_array(expected_attributes)
    end
  end
end