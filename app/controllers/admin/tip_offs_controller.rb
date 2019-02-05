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
        redirect_to(admin_tip_offs_path, notice: "举报跟进成功")
      end
    end

    private

    def set_tip_off
      @tipOff = TipOff.find(params[:id])
    end

  end
end
