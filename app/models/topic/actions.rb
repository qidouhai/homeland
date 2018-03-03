# frozen_string_literal: true

class Topic
  module Actions
    extend ActiveSupport::Concern

    # 删除并记录删除人
    def destroy_by(user)
      return false if user.blank?
      update_attribute(:who_deleted, user.login)
      destroy
    end

    def destroy
      super
      delete_notification_mentions
    end

    def excellent?
      excellent >= 1
    end

    def ban!(opts = {})
      transaction do
        update(lock_node: true, node_id: Node.no_point.id, admin_editing: true)
        if opts[:reason]
          Reply.create_system_event(action: "ban", topic_id: self.id, body: opts[:reason])
        end
      end
    end

    def down!
      transaction do
        update!(last_active_mark: self.last_active_mark - 2.day.to_i)
        # Reply.create_system_event(action: "down", topic_id: self.id)
      end
    end

    def excellent!
      transaction do
        Reply.create_system_event(action: "excellent", topic_id: self.id)
        update!(excellent: 1)
      end
    end

    def unexcellent!
      transaction do
        Reply.create_system_event(action: "unexcellent", topic_id: self.id)
        update!(excellent: 0)
      end
    end

  end
end
