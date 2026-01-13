ActiveAdmin.register Member do
  permit_params :name, :email, :phone, :bio, :birth_date,
                :favorite_author_id, :password, :password_confirmation,
                liked_category_ids: []
  config.per_page = [10, 20, 50, 100]
  controller do
    def scoped_collection
      super.includes(
        :borrowings,
        :liked_categories,
        :favorite_author,
        borrowings: :book,
        reservations: :book
      )
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :phone
    column :birth_date

    column "Active Borrowings" do |m|
      m.borrowings.borrowed.size
    end

    column :created_at
    actions
  end

  filter :name
  filter :email
  filter :birth_date

  filter :liked_categories,
         as: :select,
         label: "Liked Categories",
         collection: -> { Category.order(:name) }

  filter :created_at

  form do |f|
    f.inputs "Member Details" do
      f.input :name
      f.input :email
      f.input :phone
      f.input :birth_date, as: :datepicker
      f.input :bio

      f.input :favorite_author,
              as: :select,
              collection: -> { Author.order(:name) }

      f.input :liked_categories,
              as: :select,
              collection: -> { Category.order(:name) },
              input_html: { multiple: true }
    end

    f.inputs "Password" do
      f.input :password, required: false
      f.input :password_confirmation, required: false
    end

    f.actions
  end

  show do
    attributes_table do
      row :name
      row :email
      row :phone
      row :bio
      row :birth_date

      row "Favorite Author" do |m|
        link_to m.favorite_author.name, [:admin, m.favorite_author] if m.favorite_author
      end

      row "Interested Categories" do |m|
        m.liked_categories.map(&:name).join(", ")
      end

      row :created_at
      row :updated_at
    end

    panel "Current Borrowings" do
      table_for resource.borrowings.borrowed.order(due_date: :asc).limit(10) do
        column("Book") { |b| link_to b.book.title, admin_book_path(b.book) }
        column :borrowed_date
        column :due_date
        column :returned_date
        column :status
      end
    end

    panel "Reservations" do
      table_for resource.reservations.order(created_at: :desc) do
        column("Book") { |r| link_to r.book.title, admin_book_path(r.book) }
        column :reservation_date
        column :status
      end
    end
  end
end
