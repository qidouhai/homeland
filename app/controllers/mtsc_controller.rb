class MtscController < ApplicationController
  def conf2018
    render template: "mtsc/conf2018", handler: [:erb], layout: 'mtsc'
  end

  def conf2019
    render template: "mtsc/conf2019", handler: [:erb], layout: 'mtsc'
  end

  def conf2019en
    render template: "mtsc/conf2019en", handler: [:erb], layout: 'mtsc'
  end

end