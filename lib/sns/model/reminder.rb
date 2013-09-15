# encoding: utf-8
module Sns::Model::Reminder

  def set_reminder
    return false unless enable_reminder
    return false unless reminder_show
    attributes = post_params
    begin
      item = Gw::PlusUpdate.new(attributes)
    rescue
      item = nil
    end
    return false if item.blank?
    item.save(:validate=>false)
    return true
  end


  def post_params
    item_project = self.project
    item_title = "#{item_project.title}"
    doc_uri = self.doc_uri
    item_body = self.activity_body
    item_created_user = ""
    item_created_user = self.created_user.name unless self.created_user.blank?
    content_id = nil
    content_id = self.content_id[0].to_s if !self.content_id.blank?
    attribute_params = {
        :doc_id               =>content_id,
        :post_id              =>self.id.to_s,
        :state                =>show_status(item_project),
        :project_users        =>"",
        :project_users_json   =>target_users(item_project),
        :project_id           =>item_project.id.to_s,
        :project_code         =>item_project.code,
        :class_id             =>1,
        :title                =>item_title,
        :doc_updated_at       =>self.updated_at,
        :author               =>item_created_user,
        :project_url          =>item_project.project_uri,
        :body                 =>item_body
    }
    return attribute_params
  end

  def update_reminder
    return false unless enable_reminder
    if self.kind=="thread"
      post_item  = Sns::Post.where({:kind=>"project_thread",:content_id=>self.id}).first
    else
      post_item  = Sns::Post.where({:kind=>"project_comment",:content_id=>self.id}).first
    end
    return false if post_item.blank?
    attributes = post_item.post_params
    item = Gw::PlusUpdate.find(:first, :conditions=>["doc_id = ?",self.id.to_s], :order=>"updated_at desc") rescue nil
    return false if item.blank?
    item.attributes = attributes
    item.save(:validate=>false)
    return true
  end

  def destroy_reminder
    return false unless enable_reminder
    return false unless reminder_show
    item = Gw::PlusUpdate.find(:first, :conditions=>["post_id = ?",self.id.to_s], :order=>"updated_at desc") rescue nil
    return false if item.blank?
    item.destroy
    return true
  end

  def reminder_show
    return true if self.privacy=="project_activity"
    return true if self.kind[0]=="project_thread" || self.kind[0]=="project_comment"
    return false
  end

  def target_users(project=nil)
    ret = "["
    return "[]" if project.blank?
    project.members.each do |m|
      m_user = m.user
      next if m_user.blank?
      ret << %Q(\"#{m_user.account}\",)
    end unless project.members.blank?
    ret += "]"
    return ret
  end

  def show_status(project=nil)
    ret = "disabled"
    ret = "enabled" if project.reminder_show.to_i == 1 unless project.blank?
    return ret
  end


  def enable_reminder
     use_reminder = false
    begin
      rails_env = ENV['RAILS_ENV']
      config = YAML.load_file('config/core.yml')
      use_reminder = config[rails_env]['reminder']
    rescue
      return false
    end
    return use_reminder
  end

end
