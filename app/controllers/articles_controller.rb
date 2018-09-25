# frozen_string_literal: true


# 专栏文章称为 article ，model 层继续用 topic
class ArticlesController < ApplicationController

  def index
    @articles = Article.all
  end

  def new
  end

  def show
    # TODO: 增加筛选，不返回非本专栏的文章
    @article = Article.find(params[:id])
  end

  def edit
  end

  def update

  end

  def destroy

  end

  def new
    @article = Article.new(user_id: current_user.id, column_id: params[:column_id])
  end

  def create
    @article = Article.new(article_params)
    @article.user_id = current_user.id
    @article.column_id = article_params[:column_id]
    # 固定给一个 node id 占位
    @article.node_id = "1"

    if params[:commit] and params[:commit] == 'draft'
      @article.draft = true
    else
      @article.draft = false
    end

    @article.save
  end

  protected

  def article_params
    params.require(:article).permit(:title, :body, :node_id, :column_id, :cannot_be_shared)
  end

end

