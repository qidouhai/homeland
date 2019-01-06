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
    @tipOff.create_time = Time.now
    if @tipOff.save
      redirect_to((@tipOff['content_url']),  notice: '举报创建成功')
    else
      redirect_to((@tipOff['content_url']),  notice: '举报创建失败')
    end
  end

  private

  def tip_off_params
    params.require(:tip_off).permit(:reporter_email, :tip_off_type, :body, :content_url)
  end

end