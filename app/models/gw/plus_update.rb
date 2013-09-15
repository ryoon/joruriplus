# encoding: utf-8
class Gw::PlusUpdate < ActiveRecord::Base
  establish_connection :jorurigw rescue nil
  include Sys::Model::Base
  include Sys::Model::Base::Config


end
