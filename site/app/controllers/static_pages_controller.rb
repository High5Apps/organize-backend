class StaticPagesController < ApplicationController
  before_action :set_email, only: [ :about, :privacy, :terms ]

  def about
  end

  def privacy
  end

  def terms
  end

  private

  def set_email
    @email = "GetOrganizeApp@gmail.com"
  end
end
