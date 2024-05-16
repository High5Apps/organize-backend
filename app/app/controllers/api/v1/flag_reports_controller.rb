class Api::V1::FlagReportsController < ApplicationController
  before_action :authenticate_user, only: [:index]
  before_action :check_can_moderate, only: [:index]

  def index
    initial_flags = authenticated_user.org&.flags
    query = FlagReport::Query.new initial_flags, params
    render json: {
      flags: query.flag_reports,
      meta: pagination_dict(query.relation),
    }
  end
end
