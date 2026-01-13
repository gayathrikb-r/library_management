ActiveAdmin.register Author do
  includes :books
  permit_params :name, :biography, :birth_date
  config.per_page = [10, 20, 50, 100]
  index do
    selectable_column
    id_column
    column :name
    column :birth_date
    column("Books Count") { |a| a.books.count }
    column :created_at
    actions
  end

  filter :name
  filter :birth_date
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :biography, as: :text
      f.input :birth_date, as: :datepicker
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :biography
      row :birth_date
      row "Age" do |author|
        author.birth_date ? ((Date.today - author.birth_date) / 365.25).floor : "N/A"
      end
      row :created_at
      row :updated_at
    end

   panel "Books by this Author (#{author.books.size})" do
      table_for author.books.order(:title) do
        column "Title" do |b|
          link_to b.title, admin_book_path(b)
        end
        column :isbn
        column :publication_year
        column :average_rating
        column :available_copies
      end
    end

  end
end
