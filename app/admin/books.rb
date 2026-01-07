ActiveAdmin.register Book do
  includes :authors,:categories,:tags, :reviews,:borrowings
  permit_params :title,:isbn,:total_copies,:available_copies,
  :description,author_ids: [],tag_ids: [],category_ids: []
  index do
    selectable_column
    id_column
    column :title
    column :isbn
    column("Authors") { |b| b.authors.map(&:name).join(", ") }
    column :total_copies
    column :available_copies
    column("Avg Rating") {|b| b.average_rating}
    column("Reviews")   { |b| b.reviews.size }
    column :created_at
    actions
  end
  filter :title
  filter :isbn
  filter :authors
  filter :categories
  filter :created_at
  form do |f|
    f.inputs do
    f.input :title
    f.input :isbn
    f.input :description
    f.input :total_copies
    f.input :available_copies
    f.input :authors, as: :select, collection: Author.order(:name),input_html: {multiple: true}
    f.input :categories, as: :select, collection: Category.order(:name),input_html: {multiple: true}      
    end
  f.actions
  end
  show do
    attributes_table do
      row :title
      row :isbn
      row :description
      row :total_copies
      row :available_copies
      row("Avg Rating") { book.average_rating }
      row("Reviews") {book.reviews.size}
      row("Authors") do
        safe_join(
          book.authors.map { |a| link_to a.name, [:admin, a] },
          ", "
        )
      end

      row("Categories"){ book.categories.map(&:name).join(", ") }
      row("Tags")      { book.tags.map(&:name).join(", ") }
      row :created_at
      row :updated_at
    end
  panel "Borrowing History" do
    table_for book.borrowings.order(created_at: :desc).limit(10) do
     column "Member" do |borrowing|
      link_to borrowing.member.name, admin_member_path(borrowing.member)
    end
      column :borrowed_date
      column :due_date
      column :returned_date
      column :status
    end
  end
  panel "Reviews" do
    table_for book.reviews.order(created_at: :desc) do
      column("Reviewer") do |r|
        link_to r.reviewer.name,polymorphic_path([:admin,r.reviewer])
      end
      column :rating
      column :comment
      column :status
      column :created_at
    end
  end  
  end
end