class ReservationMailer < ApplicationMailer
  def book_available_notification(reservation)
    @reservation = reservation
    @member = reservation.member
    @book = reservation.book

    mail(to: @member.email, subject: "Book Available: #{@book.title}")
  end
end