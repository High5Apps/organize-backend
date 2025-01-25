class StaticPagesController < ApplicationController
  before_action :set_email, only: [ :about, :privacy, :terms ]

  caches_page :about,
    :aeiou_framework,
    :blog,
    :community_allies,
    :frequently_asked_questions,
    :home,
    :negotiations,
    :privacy,
    :structure_tests,
    :terms,
    :tips_for_organic_leader_identification,
    :tips_for_organizing_conversations,
    :tips_for_starting_a_union,
    :union_busting_defenses,

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
