require 'rails_helper'

RSpec.describe Review, type: :model do

  subject { build(:review) }

  describe 'associations' do
    it { should belong_to(:reviewable) }
    it { should belong_to(:reviewer) }
  end

  describe 'validations' do
    it { should validate_inclusion_of(:rating).in_range(1..5) }
    it { should validate_length_of(:comment).is_at_least(10).is_at_most(1000) }

    context 'uniqueness' do
      subject { create(:review) }
      it do
        should validate_uniqueness_of(:reviewer_id)
          .scoped_to(:reviewer_type, :reviewable_id, :reviewable_type)
          .with_message("has already reviewed this item")
      end
    end
  end

  describe 'scopes' do
    let!(:pending_review) { create(:review, status: :pending) }
    let!(:approved_review) { create(:review, status: :approved) }
    
    describe '.recent' do
      it 'orders by created_at desc' do
        pending_review.update(created_at: 1.day.ago)
        approved_review.update(created_at: 1.hour.ago)
        expect(Review.recent).to eq([approved_review, pending_review])
      end
    end


    describe '.pending_first' do
      it 'orders pending reviews before approved ones' do
        expect(Review.pending_first).to eq([pending_review, approved_review])
      end
    end
  end

  describe 'instance methods' do
    let(:review) { create(:review, status: :pending) }


    describe '#approve!' do
      it 'updates status to approved' do
        review.approve!
        expect(review.reload).to be_approved
      end
    end


    describe '#flag!' do
      it 'updates status to pending' do
        review.update(status: :approved)
        review.flag!
        expect(review.reload).to be_pending
      end
    end
  end

  describe 'callbacks' do
    let(:book) { create(:book) }

    describe '#strip_comment' do
      it 'removes whitespace from start and end' do
        review = create(:review, comment: '  Great book!  ')
        expect(review.comment).to eq('Great book!')
      end
    end

    describe '#update_reviewable_rating' do
      it 'calls update_average_rating! on create' do
        expect(book).to receive(:update_average_rating!)
        create(:review, reviewable: book, rating: 5)
      end

      it 'calls update_average_rating! on update if rating changes' do
        review = create(:review, reviewable: book, rating: 3)
        expect(book).to receive(:update_average_rating!)
        review.update(rating: 5)
      end

      it 'calls update_average_rating! on destroy' do
        review = create(:review, reviewable: book)
        expect(book).to receive(:update_average_rating!)
        review.destroy
      end

      it 'does not crash if reviewable does not support ratings' do
        review = build(:review)
        plain_object = double("PlainObject")
    
        allow(review).to receive(:reviewable).and_return(plain_object)
       expect { review.send(:update_reviewable_rating) }.not_to raise_error
      end
    end
  end


  describe 'ransackable configuration' do
    describe '.ransackable_attributes' do
      it 'returns the allowed list of attributes' do
        expected = ["comment", "created_at", "id", "id_value", "rating", "reviewable_id", "reviewable_type", "reviewer_id", "reviewer_type", "status", "updated_at"]
        expect(Review.ransackable_attributes).to match_array(expected)
      end
    end

    describe '.ransackable_associations' do
      it 'returns the allowed list of associations' do
        expected = ["reviewable", "reviewer"]
        expect(Review.ransackable_associations).to match_array(expected)
      end
    end
  end
end