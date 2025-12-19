class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_user, :logged_in?, :librarian?
  # before_action :require_login
  def current_user
    # @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
      @current_user ||= User.first
  end
  def logged_in?
    # current_user.present?
    true
  end
  def librarian?
    # logged_in? && current_user.librarian? 
      true
  end
  def require_login
    # unless logged_in?
    #   flash[:alert] = "You must be logged in to access this page"
    #   redirect_to login_path
    # end
      return
  end
  def require_librarian
    return
    # unless librarian?
    #   flash[:alert] = "You must be a librarian to access this page"
    #   redirect_to root_path
    # end
  end
  def skip_login_required
  # This allows certain actions to skip login
  end




end
