class AddIndexToTipOff < ActiveRecord::Migration[5.2]
  def change
    # "我的举报" 会根据举报人搜索
    add_index :tip_offs, :reporter_id

    # 管理员批量处理举报时，会根据 content_url 搜索
    add_index :tip_offs, :content_url
  end
end