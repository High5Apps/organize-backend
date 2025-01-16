class V1::ModerationEventsController < ApplicationController
  PERMITTED_CREATE_PARAMS = [
    :action,
    :moderatable_id,
    :moderatable_type,
  ]

  before_action :check_can_block_members, only: [:create], if: :moderating_user?
  before_action :check_can_moderate, only: [:create], unless: :moderating_user?

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

  def index
    initial_moderation_events = authenticated_user.org&.moderation_events
    @query = ModerationEvent::Query.build initial_moderation_events, params
    render json: {
      moderation_events:,
      meta: pagination_dict(@query),
    }
  end

  private

  def create_params
    params.require(:moderation_event).permit(PERMITTED_CREATE_PARAMS)
  end

  def moderating_user?
    create_params[:moderatable_type] == 'User'
  end

  def moderation_events
    @query.includes(moderatable: :user).map do |me|
      user = me.moderatable_user? ? me.moderatable : me.moderatable.user
      {
        action: me.action,
        created_at: me.created_at,
        id: me.id,
        moderatable: {
          category: me.moderatable_type,
          creator: {
            id: user.id,
            pseudonym: user.pseudonym,
          },
          id: me.moderatable_id,
        },
        moderator: {
          id: me.user_id,
          pseudonym: me.user_pseudonym,
        },
      }
    end
  end
end
