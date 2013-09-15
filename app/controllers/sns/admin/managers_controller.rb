class Sns::Admin::ManagersController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def index
    return redirect_to "/_admin" unless Core.user.has_auth?(:manager)
  end


protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end
end
