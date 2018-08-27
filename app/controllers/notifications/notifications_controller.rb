# frozen_string_literal: true

module Notifications
  class NotificationsController < Notifications::ApplicationController
    def index
      # 跳转优先级：system > team > personal ，默认 system
      for available_group in Notification.available_groups
        if Notification.unread_count_by_group(current_user, available_group) > 0
          redirect_to group_by_type_notifications_path(group: available_group)
          return
        end
      end
      redirect_to group_by_type_notifications_path(group: Notification.default_group)
    end

    def group_by_type
      group = params[:group]
      if group.nil? or !Notification.available_group?(group)
        render_404
        return
      end

      @notifications = notifications.where(notify_type: Notification.get_notify_types_by_group(group))
                           .includes(:actor).order("id desc").page(params[:page])

      unread_ids = @notifications.reject(&:read?).select(&:id)
      Notification.read!(unread_ids)

      @notification_groups = @notifications.group_by { |note| note.created_at.to_date }

      Notification.realtime_push_to_client(current_user)

      render action: "index"
    end

    def clean
      group = params[:group]
      if group.nil? or !Notification.available_group?(group)
        render_404
        return
      end

      notifications.where(notify_type: Notification.get_notify_types_by_group(group)).delete_all
      redirect_to group_by_type_notifications_path(group: group)
    end

    private

      def notifications
        Notification.where(user_id: current_user.id)
      end
  end
end
