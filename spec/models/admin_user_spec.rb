require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  subject(:admin_user) { build(:admin_user) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }

    context 'email format' do
      it 'is invalid with incorrect email format' do
        admin_user.email = 'invalid_email'
        expect(admin_user).not_to be_valid
      end
    end
  end

  describe 'class methods' do
    describe '.ransackable_attributes' do
      it 'returns allowed searchable attributes' do
        expect(described_class.ransackable_attributes).to match_array(
          %w[id email created_at updated_at]
        )
      end
    end

    describe '.ransackable_associations' do
      it 'returns an empty array' do
        expect(described_class.ransackable_associations).to eq([])
      end
    end
  end
end
