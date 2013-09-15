# encoding: utf-8
class Sns::Script::Tool
  def self.message_reset
    #一行メッセージをリセットする処理
    dump "Sns::Script::Tool.message_reset 一行メッセージをリセットする自動処理、#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}に作業開始"
    Sns::Profile.update_all(:message=>"")
    dump "Sns::Script::Tool.message_reset 一行メッセージをリセットする自動処理、#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}に作業終了"
  end

end
