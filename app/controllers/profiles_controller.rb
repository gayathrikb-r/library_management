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
      # to clean up liked_genres parameter
      if params[:profile][:liked_genres].present?
          if params[:profile][:liked_genres].is_a?(Array)
            params[:profile][:liked_genres] = params[:profile][:liked_genres].reject(&:blank?)
          elsif params[:profile][:liked_genres].is_a?(String)
            params[:profile][:liked_genres] = params[:profile][:liked_genres].blank? ? [] : [params[:profile][:liked_genres]]
          end
      else
          params[:profile][:liked_genres] = []
      end
      if @profile.update(profile_params)
        flash[:notice] = "Profile updated successfully"
        redirect_to "/users/#{@user.id}/profile"
      else
        render :edit, status: :unprocessable_entity
      end
    end
  private
  def set_user
     @user = current_user
  end
  def require_correct_user

  end
  
  def profile_params
    params.require(:profile).permit(:bio, :birth_date, :favorite_author_id, liked_genres: [])
  end

end
