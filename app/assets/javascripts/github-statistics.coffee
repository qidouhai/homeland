window.GitHubStatisticsView = Backbone.View.extend
  el: "body"
  events:
    "click button#display-all": "toggleDisplayAll"

  initialize: (opts) ->
    @parentView = opts.parentView
    # 默认隐藏非社区用户
    $('div.not_testehome_user').attr('style', 'display: none')

  toggleDisplayAll: (e) ->
    btn = $(e.currentTarget)
    if btn.hasClass("active")
      $('div.not_testehome_user').attr('style', 'display: none')
    else
      btn.removeClass("focus")
      $('div.not_testehome_user').removeAttr('style', '')