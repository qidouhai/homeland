# frozen_string_literal: true

module Admin
  class ColumnsController < Admin::ApplicationController
    def index
      @columns = Column.all
    end
  end
end
