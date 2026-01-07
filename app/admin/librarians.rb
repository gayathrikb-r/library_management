ActiveAdmin.register Librarian do
  permit_params :name, :email, :phone, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :phone
    column("Borrowings Processed") { |l| l.processed_borrowings.count }
    column :created_at
    actions
  end

  filter :name
  filter :email
  filter :created_at

  form do |f|
    f.inputs "Librarian Details" do
      f.input :name
      f.input :email
      f.input :phone
    end

    f.inputs "Password" do
      f.input :password
      f.input :password_confirmation
    end

    f.actions
  end

  show do
    attributes_table do
      row :name
      row :email
      row :phone
      row :created_at
    end

    panel "Recent Borrowings Processed (#{librarian.processed_borrowings.count})" do
      table_for librarian.processed_borrowings.includes(:member, :book).order(created_at: :desc).limit(10) do
        column("Member") { |b| link_to b.member.name, admin_member_path(b.member) }
        column("Book") { |b| link_to b.book.title, admin_book_path(b.book) }
        column :borrowed_date
        column :due_date
        column("Status") do |b|
        status = b.status.to_s
        status_tag(
          status.titleize,
          class: status == "overdue" ? "error" : "ok"
        )

      end
      end
    end
  end
end
