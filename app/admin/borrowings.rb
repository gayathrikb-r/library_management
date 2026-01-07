ActiveAdmin.register Borrowing do
  permit_params :member_id,:book_id,:borrowed_date, :due_date,
                :returned_date, :librarian_id, :status
  scope :all,default: true
  scope :borrowed
  scope :returned
  scope :overdue
  controller do
    def scoped_collection
      super.includes(:member,:book,:librarian)
    end
  end
 index do
  selectable_column
  id_column

  column("Member") { |b| link_to b.member.name, admin_member_path(b.member) }
  column("Book")   { |b| link_to b.book.title, admin_book_path(b.book) }
  column :borrowed_date
  column :due_date
  column :returned_date

  column :status do |b|
    status_tag b.status
  end

  column "Overdue?" do |b|
    if b.overdue?
      status_tag "Yes", class: "error"
    else
      status_tag "No", class: "ok"
    end
  end

  actions
end

  filter :member
  filter :book
  filter :borrowed_date
  filter :due_date
  filter :returned_date
  filter :status, as: :select, collection: Borrowing.statuses.keys
  filter :librarian
  form do |f|
    borrowing = f.object
    books = Book.where("available_copies > 0").or(Book.where(id: borrowing.book_id))

    f.inputs do
      f.input :member, as: :select, collection: Member.order(:name)
      f.input :book, as: :select, collection: books.order(:title)
      f.input :borrowed_date, as: :datepicker
      f.input :due_date, as: :datepicker
      f.input :returned_date, as: :datepicker
      f.input :librarian, as: :select, collection: Librarian.order(:name)
      f.input :status, as: :select, collection: Borrowing.statuses.keys
    end
    f.actions
  end
  action_item :return_book,only: :show do
    link_to "Mark as Returned", return_book_admin_borrowing_path(resource), method: :put,if: resource.borrowed? 
  end

  member_action :return_book,method: :put do
    borrowing=Borrowing.find(params[:id])
  Borrowing.transaction do
    borrowing.update!(
        returned_date: Date.today,
        status: :returned
      )
      borrowing.book.increment!(:available_copies)
  end
  redirect_to admin_borrowing_path(borrowing),
                notice: "Book returned successfully!"
  end
end