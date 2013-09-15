class Sys::Session < ActiveRecord::Base
  set_table_name 'sessions'
  
  def self.delete_past_sessions_at_random(days = 3, rand_max = 10000)
    return unless rand(rand_max) == 0
    cond = ["created_at < ?", Date.strptime(Core.now, '%Y-%m-%d') - days]
    self.delete_all(cond)
  end
  
end