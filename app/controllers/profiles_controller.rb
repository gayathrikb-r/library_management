class ProfilesController < ApplicationController
  before_action :set_user
  # before_action :require_correct_user

  def show
    @profile = @user.profile
  end

  def edit
    @profile = @user.profile
  end

  def update
    @profile = @user.profile
    # Clean up empty values from multi-select
    if params[:profile][:liked_genres]
      params[:profile][:liked_genres] = params[:profile][:liked_genres].reject(&:blank?)
    end
    if @profile.update(profile_params)
      flash[:notice]="Profile updated successfully!"
      redirect_to user_profile_path(@user)
    else
      render :edit, status: :unprocessable_entity
    end
  end
  private
  def set_user
    @user = User.find(params[:user_id])
  end
  def require_correct_user
    # unless current_user == @user
    #   flash[:alert] = "Not authorized"
    #   redirect_to root_path
    # end
  end
  
  def profile_params
    params.require(:profile).permit(:bio, :birth_date, :favorite_author_id, liked_genres: [])
  end

end
