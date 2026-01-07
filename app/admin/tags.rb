ActiveAdmin.register Tag do
  permit_params :name

  controller do
    def scoped_collection
      super.includes(:books)
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column "Books Count" do |tag|
      tag.books.size
    end
    column :created_at
    actions
  end

  filter :name
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
    end
    f.actions
  end
end
