class V1::FlagReportsController < ApplicationController
  before_action :check_can_moderate, only: [:index]

  def index
    query = FlagReport::Query.new authenticated_user.org, params
    render json: {
      flag_reports: query.flag_reports,
      meta: pagination_dict(query.relation),
    }
  end
end
