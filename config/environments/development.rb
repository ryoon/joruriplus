Joruri::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Sendmail
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings   = {
    :address        => 'localhost',
    :port           => 25,
    :domain         => 'your-domain',
    :user_name      => nil,
    :password       => nil,
    :authentication => nil
  }
  #Session
  Joruri.config.session_settings = {
    :timeout => 24 * 3 #hours
  }

  # SSO
  Joruri.config.sso_settings = {
    :gw => {
      :host        => 'localhost',
      :port        => 80,
      :usessl      => false,
      :path        => 'api/air_sso'
    },
    :hss => {
      :host        => 'localhost',
      :port        => 80,
      :usessl      => false,
      :path        => '_admin/air_sso'
    },
    :video => {
      :host        => 'localhost',
      :port        => 80,
      :usessl      => false,
      :path        => '_admin/air_sso'
    },
    :sns => {
      :host        => 'localhost',
      :port        => 80,
      :usessl      => false,
      :path        => '_admin/air_sso'
    }
  }

end

