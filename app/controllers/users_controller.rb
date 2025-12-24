class UsersController < ApplicationController

  before_action :set_user, only: [:show,:edit,:update,:destroy,:dashboard]

  def new
    @user=User.new
  end

  def create
    @user=User.new(user_params)
    @user.membership_date = Date.today
    if @user.save
      session[:user_id]=@user.id
      flash[:notice]="Account created successfully!"
      redirect_to user_dashboard_path(@user)
    else
      render :new, status: :unprocessable_entity
    end
  
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:notice] = "Account updated successfully"
      redirect_to @user
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def dashboard
    @active_borrowings=@user.borrowings.where(status: "active")
    @reservations=@user.reservations.where(status: "pending")
    @recent_reviews= @user.reviews.order(created_at:  :desc).limit(5)
  end
  def destroy
    if @user.destroy
      flash[:notice] = "Account deleted"
    else
      flash[:alert] = @user.errors.full_messages.to_sentence
    end
    redirect_to root_path
  end
  private 
  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :name,
      :email,
      :password,
      :password_confirmation,
      :phone
    )
  end

  def require_correct_user_or_librarian

  end
end
