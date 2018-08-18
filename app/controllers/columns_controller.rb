class ColumnsController < ApplicationController
  before_action :set_column, only: [:show]

  def index
    @columns = Column.all
  end

  def new
    @column = Column.new(user_id: current_user.id)
  end

  def show
  end

  def create
    @column = Column.new(column_params)
    Rails.logger.error "asdasasdasd #{current_user}"
    @column.user_id = current_user.id
    if @column.save
      redirect_to(column_path(@column), notice: 'Column was created successfully.')
    else
      set_flash_message :warning, :"Column cannnot be created."
      render action: "new"
    end

  end

  def edit
    @column = Column.find(params[:id])
  end

  def update
    @column = Column.find(params[:id])

    if @column.update_attributes(column_params)
      redirect_to(columns_path, notice: 'Column was successfully updated.')
    else
      render action: "edit"
    end
  end

  def destroy
    @column = Column.find(params[:id])
    @column.destroy

    redirect_to(columns_url)
  end

  protected

  def column_params
    params.require(:column).permit(:name, :description, :cover)
  end

  def set_column
    Rails.logger.error "###{column_params[:name]}"
    @column = Column.find_by(name: column_params[:name])
  end
end