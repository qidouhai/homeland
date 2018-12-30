class TipOffsController < ::ApplicationController

  def new
    @tipOff = TipOff.new(reporter_id: current_user.id, reporter_email: current_user.email)
  end

  def index
    @tipOffs = TipOff.find_by_reporter_id(current_user.id)
  end

  def create
    @tipOff = TipOff.new(tip_off_params)
    @tipOff.reporter_id = current_user.id
    if @tipOff.save
      redirect_to((@tipOff.url),  notice: '举报创建成功')
    else
      redirect_to((@tipOff.url),  notice: '举报创建失败，失败原因：')
    end
  end

  private

  def tip_off_params
    params.require(:tipOff).permit(:reporter_email, :type, :body, :url)
  end

end