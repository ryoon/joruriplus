module Joruri
  def self.version
    "1.0.2"
  end

  def self.config
    $joruri_config ||= {}
    Joruri::Config
  end

  class Joruri::Config
    def self.session_settings
      $joruri_config[:session_settings]
    end

    def self.session_settings=(config)
      $joruri_config[:session_settings] = config
    end

    def self.sso_settings
      $joruri_config[:sso_settings]
    end

    def self.sso_settings=(config)
      $joruri_config[:sso_settings] = config
    end
  end
end
