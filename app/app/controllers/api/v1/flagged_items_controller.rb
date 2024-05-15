class Api::V1::FlaggedItemsController < ApplicationController
  PERMITTED_PARAMS = [:flaggable_id, :flaggable_type]

  before_action :authenticate_user, only: [:index, :create]
  before_action :check_can_moderate, only: [:index]

  def create
    flagged_item = authenticated_user.flagged_items.create_with(create_params)
      .create_or_find_by(create_params)

    # update will no-op in the usual case where flag didn't already exist
    if flagged_item.update(create_params)
      head :created
    else
      render_error :unprocessable_entity, flagged_item.errors.full_messages
    end
  end

  def index
    initial_flagged_items = authenticated_user.org&.flagged_items
    query = FlaggedItem::Query.new initial_flagged_items, params
    render json: {
      flagged_items: query.flag_reports,
      meta: pagination_dict(query.relation),
    }
  end

  private

  def create_params
    params.require(:flagged_item).permit(PERMITTED_PARAMS)
  end
end
