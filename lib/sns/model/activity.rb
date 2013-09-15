# encoding: utf-8
module Sns::Model::Activity

  def feed_post(privacy, post_body,post_kind, content_id,project_id,is_project,options={})
    if options[:created_user]
      created_user = options[:created_user]
    else
      created_user = Core.profile
    end
    attribute = {
            :text =>post_body,
            :kind =>post_kind,
            :content_id=>content_id,
            :privacy =>privacy,
            :created_user_id=>created_user.id,
            :project_id=>project_id,
            :is_project=>is_project,
            :proposal_id=>options[:proposal_id],
            :schedule_id=>options[:schedule_id],
            :exclude_user_id=>options[:exclude_id]
          }
    Sns::Post.create(attribute)
  end

  def manager_config
    return Sns::Management.global_setting
  end

end
