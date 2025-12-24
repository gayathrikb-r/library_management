class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_user, :logged_in?, :librarian?

  def current_user
      @current_user ||= User.first
  end
  def logged_in?
    true
  end
  def librarian?
      true
  end
  def require_login
      nil
  end
  def require_librarian
    nil
  end
  def skip_login_required
    # This allows certain actions to skip login
  end
end
