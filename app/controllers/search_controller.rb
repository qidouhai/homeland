class SearchController < ApplicationController
  before_action :authenticate_user!, only: [:users]

  def index
    params[:q] ||= ''

    search_modules = [Topic, User]
    search_modules << Page if Setting.has_module?(:wiki)
    search_params = {
        sort: [
            {type_order: {order: "desc", ignore_unmapped: true}},
            {updated_at: {order: "desc", ignore_unmapped: true}},
            {excellent: {order: "desc", ignore_unmapped: true}}
        ],
        query: {
            multi_match: {
                query: params[:q],
                fields: ['title', 'body', 'name', 'login'],
                fuzziness: 2,
                prefix_length: 5,
                operator: :and
            }
        },
        highlight: {
            pre_tags: ["[h]"],
            post_tags: ["[/h]"],
            fields: {title: {}, body: {}, name: {}, login: {}}
        }
    }
    @result = Elasticsearch::Model.search(search_params, search_modules).page(params[:page])
  end

  def users
    @result = User.search(params[:q], user: current_user, limit: params[:limit] || 10)
    render json: @result.collect { |u| { login: u.login, name: u.name, avatar_url: u.large_avatar_url } }
  end
end
