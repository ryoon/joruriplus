class SessionScript
  
  def self.clear
    puts "#{Time.now.to_s(:db)} Start SessionScript.clear"
    begin
      conf = Joruri.config.session_settings
      raise 'Timeout is not found.' unless conf && !conf[:timeout].blank?
      Sys::Session.delete_all(["updated_at < ?", conf[:timeout].hours.ago])      
    rescue => e
      error_log(e.to_s)
      puts "Error: #{e}" 
    end
    puts "#{Time.now.to_s(:db)} End SessionScript.clear"
  end
  
end