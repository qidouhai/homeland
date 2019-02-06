# frozen_string_literal: true

module Admin
  class TipOffsController < Admin::ApplicationController
    before_action :set_tip_off, only: %i[edit update]

    def index
      @tipOffs = TipOff.all.order(create_time: :desc, follow_time: :desc)
    end

    def edit
      @tipOff = TipOff.find(params[:id])
    end

    def update
      if @tipOff.update(params.require(:tip_off).permit(:follower_id))
        # 给管理员群发通知
        admin_users = User.admin_users
        default_note = {notify_type: "admin_follow_tip_off", target_type: TipOff,
                        target_id: @tipOff.id, actor_id: current_user.id
        }
        Notification.bulk_insert(set_size: 100) do |worker|
          admin_users.each do |admin_user|
            note = default_note.merge(user_id: admin_user[:id])
            worker.add(note)
          end
        end

        # 给举报者单独发通知
        opts = {
            notify_type: "follow_tip_off",
            user_id: @tipOff.reporter_id,
            actor_id: current_user.id,
            target: @tipOff
        }
        return if Notification.where(opts).count > 0
        Notification.create opts
        Notification.realtime_push_to_client(@tipOff.reporter)

        redirect_to(admin_tip_offs_path, notice: "您已成功跟进此举报")
      end
    end

    private

    def set_tip_off
      @tipOff = TipOff.find(params[:id])
    end

  end
end
