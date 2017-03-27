class JumpController < ApplicationController
  def index
    redirect_to jump_params[:url]
  end

  private

  def jump_params
    params.permit(:url)
  end
end