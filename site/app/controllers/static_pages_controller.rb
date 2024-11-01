class StaticPagesController < ApplicationController
  before_action :set_email, only: [ :about, :privacy, :terms ]

  def about
  end

  def blog_tips_for_starting_a_union
  end

  def frequently_asked_questions
  end

  def home
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
