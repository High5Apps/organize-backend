class Api::V1::ModerationEventsController < ApplicationController
  PERMITTED_CREATE_PARAMS = [
    :action,
    :ballot_id,
    :comment_id,
    :post_id,
    :user_id,
  ]

  before_action :authenticate_user, only: [:create]
  before_action :check_can_moderate, only: [:create]

  def create
    new_moderation_event = authenticated_user.created_moderation_events
      .build create_params
    if new_moderation_event.save
      render json: { id: new_moderation_event.id }, status: :created
    else
      render_error :unprocessable_entity,
        new_moderation_event.errors.full_messages
    end
  end

  private

  def create_params
    params.require(:moderation_event).permit(PERMITTED_CREATE_PARAMS)
  end
end
