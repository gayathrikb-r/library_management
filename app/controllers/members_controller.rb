class MembersController < ApplicationController
  before_action :authenticate_any_user!
  before_action :set_member
  before_action :authorize_member_access!

  def show
  end

  def edit
    # members only (guarded below)
  end

  def update
    if @member.update(member_params)
      redirect_to member_path(@member), notice: "Profile updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # 🔐 Allow member OR librarian
  def authenticate_any_user!
    return if member_signed_in? || librarian_signed_in?
    redirect_to root_path, alert: "Please sign in"
  end

  def set_member
    @member = Member.find(params[:id])
  end

  # 🧠 Authorization logic
  def authorize_member_access!
    return if librarian_signed_in?

    if member_signed_in?
      return if current_member == @member
    end

    redirect_to root_path, alert: "Not authorized"
  end

  def member_params
    params.require(:member).permit(
      :name,
      :phone,
      :bio,
      :birth_date
    )
  end
end
