class Api::V1::FlagsController < ApplicationController
  PERMITTED_PARAMS = [:flaggable_id, :flaggable_type]

  before_action :authenticate_user, only: [:index, :create]
  before_action :check_can_moderate, only: [:index]

  def create
    flag = authenticated_user.flags.create_with(create_params)
      .create_or_find_by(create_params)

    # update will no-op in the usual case where flag didn't already exist
    if flag.update(create_params)
      head :created
    else
      render_error :unprocessable_entity, flag.errors.full_messages
    end
  end

  def index
    initial_flags = authenticated_user.org&.flags
    query = Flag::Query.new initial_flags, params
    render json: {
      flags: query.flag_reports,
      meta: pagination_dict(query.relation),
    }
  end

  private

  def create_params
    params.require(:flag).permit(PERMITTED_PARAMS)
  end
end
