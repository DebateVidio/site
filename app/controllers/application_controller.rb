class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :redirect_if_heroku

  def authenticate_admin_user!
    redirect_to root_path unless logged_in? && current_user.is_admin
  end

  private

  def redirect_if_heroku
    redirect_to "https://debatevid.io#{request.fullpath}" if request.host == 'debatevidio.herokuapp.com'
  end
end
