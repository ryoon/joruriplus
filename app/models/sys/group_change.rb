# encoding: utf-8
class Sys::GroupChange < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Tree
  include Sys::Model::Auth::Manager

  belongs_to :group    , :foreign_key => :group_id    , :class_name => 'Sys::Group'
  belongs_to :old_group, :foreign_key => :old_id, :class_name => 'Sys::Group'

  attr_accessor :selector

  before_save :set_old_group

  def kind_select
    select = [["新規所属プロジェクト",1],["所属プロジェクト名称変更",2],["所属プロジェクト引継ぎ",3],["所属通知振り替え",4],["所属通知非公開",5]]
    return select
  end

  def kind_show
    kind_select.each {|a| return a[0] if a[1] == change_division.to_i }
    return nil
  end

  def set_old_group
   if !self.old_group.blank? && self.old_code.blank?
      self.old_code = self.old_group.code
      self.old_name = self.old_group.name
    end
  end


  def ldap_states
    [['同期',1],['非同期',0]]
  end
  def ldap_label
    ldap_states.each {|a| return a[0] if a[1] == ldap }
    return nil
  end

  def self.truncate_table
    # テーブルを空にする
    connect = self.connection()
    truncate_query = "TRUNCATE TABLE `sys_group_changes` ;"
    connect.execute(truncate_query)
  end

end
