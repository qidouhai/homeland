class AddIndexToTipOff < ActiveRecord::Migration[5.2]
  def change
    # "我的举报" 会根据举报人搜索
    add_index :tip_offs, :reporter_id
  end
end