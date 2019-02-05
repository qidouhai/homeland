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
      # TODO: 发送提醒给管理员
      redirect_to((@tipOff['content_url']),  notice: '举报创建成功，后续管理员将会查看您的举报并进行处理。过程中可能会通过邮箱 ' + @tipOff['reporter_email'] + ' 与您联系，请留意。')
    else
      redirect_to((@tipOff['content_url']),  notice: '举报创建失败，请检查表格中所有内容是否均已填写。')
    end
  end

  def show
  end

  private

  def tip_off_params
    params.require(:tip_off).permit(:reporter_email, :tip_off_type, :body, :content_url, :content_author_id)
  end

end