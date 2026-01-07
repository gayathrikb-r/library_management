# app/admin/reviews.rb
ActiveAdmin.register Review do
  actions :all, except: [:new, :create, :edit]

  permit_params :status

  scope :all, default: true
  scope :pending
  scope :approved

  index do
    selectable_column
    id_column

    column "Reviewer" do |review|
      if review.reviewer
        link_to review.reviewer.try(:name) || review.reviewer.try(:email),
                [:admin, review.reviewer]
      else
        status_tag "Missing", :error
      end
    end

    column "Reviewable" do |review|
      if review.reviewable
        label =
          review.reviewable.respond_to?(:title) ? review.reviewable.title :
          review.reviewable.respond_to?(:name)  ? review.reviewable.name  :
          review.reviewable.class.name

        link_to label, [:admin, review.reviewable]
      else
        status_tag "Deleted", :warning
      end
    end

    column :rating do |review|
      "⭐" * review.rating.to_i
    end

    column :status do |review|
      status_tag review.status
    end

    column :created_at
    actions
  end

  filter :reviewable_type, as: :select, collection: ['Book', 'Author']
  filter :rating
  filter :status, as: :select, collection: Review.statuses
  filter :created_at

  action_item :approve, only: :show do
    link_to "Approve",
            approve_admin_review_path(resource),
            method: :put if resource.pending?
  end

  member_action :approve, method: :put do
    resource.update!(status: :approved)
    redirect_to admin_reviews_path, notice: "Review approved"
  end

end
