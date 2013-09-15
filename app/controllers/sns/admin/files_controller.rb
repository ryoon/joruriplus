# encoding: utf-8
class Sns::Admin::FilesController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout :select_layout

  def pre_dispatch
  end

  def index
    @items = Sns::File.where(:created_user_id => @created_user.id).excludes(:is_project=>1).desc(:created_at).paginate(:page => params[:page], :per_page => 20)
  end

  def show
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
  end

  def new
    @item = Sns::File.new
    @item.created_user_id = Core.profile.id
  end

  def create
    @item = Sns::File.new
    items = Sns::File.any_in("_id"=>params[:ids])
    items.each do |file|
      file.update_attributes!(:privacy => params[:item][:privacy], :caption=>params[:item][:caption])
    end
    flash[:notice]="ファイルを追加しました。"
    return redirect_to sns_files_path(@created_user.account)
  end


  def edit
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
  end

  def update
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
    if @item.file_data_save(params, :update)
      flash[:notice]="ファイルを追加しました。"
      return redirect_to sns_file_path(@created_user.account,@item)
    else
      flash[:notice]="ファイルの追加に失敗しました。"
      return redirect_to :action => 'edit'
    end
  end


  def destroy
    @item = Sns::File.find(:first, :conditions=>{:_id=>params[:id]})
    @item.destroy
    return redirect_to sns_files_path(@created_user.account)
  end

  def down
    params_path = params[:path].split('/')

    sequence = params_path[0].gsub(/\..*$/, '').to_i
    item = Sns::File.find(:first, :conditions=>{:sequence =>sequence,:file_name=>params_path[0]})
    return http_error(404) if item.blank?
    return http_error(404) unless item.auth_check

    path = "#{Rails.root.to_s}#{item.file_path}"
    return http_error(404) unless FileTest.exist?(path)

    #IE判定
    chk = request.headers['HTTP_USER_AGENT']
    chk = chk.index("MSIE")
    if chk.blank?
      item_filename = item.original_file_name
    else
      item_filename = item.original_file_name.tosjis
    end

    return send_file(path, :filename => item_filename, :disposition => 'attachment', :type=>item.content_type, :x_sendfile => true)
  end


protected

  def select_layout
    layout = "admin/sns/sns"
    layout
  end

end
