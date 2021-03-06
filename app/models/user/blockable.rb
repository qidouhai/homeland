# frozen_string_literal: true

class User
  module Blockable
    extend ActiveSupport::Concern

    included do
      action_store :block, :user
      action_store :block, :node
      action_store :block, :column
    end

    def block_users?
      block_user_actions.first.present?
    end

    def block_nodes?
      block_node_actions.first.present?
    end

    def block_columns?
      block_column_actions.first.present?
    end

  end
end
