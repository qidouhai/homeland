class ColumnsController < ApplicationController

  before_action :authenticate_user!, only: %i[new edit create update destroy]
  load_and_authorize_resource only: %i[new edit create update destroy],:find_by => :slug
  before_action :set_column, only: [:show, :edit, :update, :destroy]
  before_action :set_columns_have, only: [:new, :edit, :update, :create]

  def index
    @columns = Column.all
  end

  def new
    @column = Column.new(user_id: current_user.id)
  end

  def show
    @user = @column.user
    @articles = @column.articles.withoutDraft.page(params[:page])
  end

  def create
    @column = Column.new(column_params)
    @column.user_id = current_user.id
    if @column.save
      redirect_to(column_path(@column),  notice: I18n.t("column.column_created_successfully"))
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @column.update(column_params)
      redirect_to(column_path(@column), notice: I18n.t("column.column_updated_successfully"))
    else
      render action: "edit"
    end
  end

  def destroy
    @column.destroy
    redirect_to(columns_url)
  end

  protected

  def column_params
    params.require(:column).permit(:name, :description, :cover, :slug)
  end

  def set_column
    @column = Column.find_by_slug(params[:id])
  end

  def set_columns_have
    @column_already_have = current_user.columns
  end
end