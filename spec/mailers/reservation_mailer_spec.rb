# spec/mailers/reservation_mailer_spec.rb
require 'rails_helper' 
RSpec.describe ReservationMailer, type: :mailer do
  let(:member) { create(:member, email: "member@example.com") }
  let(:book) { create(:book, title: "Reserved Book", available_copies: 0) } 
  let(:reservation) { create(:reservation, member: member, book: book) }

  describe "#book_available_notification" do
    let(:mail) { ReservationMailer.book_available_notification(reservation) }

    it "renders the subject" do
      expect(mail.subject).to eq("Book Available: Reserved Book")
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq(["member@example.com"])
    end

    it "includes the member name and book title in the body" do
      expect(mail.body.encoded).to include(member.name)
      expect(mail.body.encoded).to include("Reserved Book")
    end
  end
end