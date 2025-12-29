class MembersController < ApplicationController
  before_action :authenticate_member!
  before_action :set_member

  def show
  end

  def edit
  end

  def update
    if @member.update(member_params)
      redirect_to member_path(@member), notice: "Profile updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_member
    @member = current_member
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

