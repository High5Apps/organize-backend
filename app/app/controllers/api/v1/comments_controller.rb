class Api::V1::CommentsController < ApplicationController
  ALLOWED_ATTRIBUTES = [
    :id,
    :encrypted_body,
    :user_id,
    :created_at,
    :pseudonym,
    :score,
    :my_vote,
    :replies,
    :depth
  ].freeze

  INTERMEDIATE_ATTRIBUTES = [
    :ancestry,
  ]

  MANUAL_SELECTIONS = (ALLOWED_ATTRIBUTES + INTERMEDIATE_ATTRIBUTES).filter do |k|
    # Either these attributes are already included by the includes_* scopes,
    # or they're not indended as selections
    ![:score, :pseudonym, :my_vote, :replies].include? k
  end.freeze
  private_constant :MANUAL_SELECTIONS

  PERMITTED_PARAMS = [
    EncryptedMessage.permitted_params(:body),
  ].freeze

  before_action :authenticate_user, only: [:index, :create]

  def create
    new_comment = authenticated_user.comments.build(create_params)
    if new_comment.save
      render json: { id: new_comment.id }, status: :created
    else
      render_error :unprocessable_entity, new_comment.errors.full_messages
    end
  end

  def index
    render json: { comments: }
  end

  private

  def comments
    post = authenticated_user.org&.posts&.find params[:post_id]
    return [] unless post

    created_at_or_before_param = \
      params[:created_at_or_before] || Upvote::FAR_FUTURE_TIME
    created_at_or_before = Time.parse(created_at_or_before_param.to_s).utc

    my_id = authenticated_user.id

    post.comments
      .created_at_or_before(created_at_or_before)
      .includes_pseudonym
      .with_upvotes_created_at_or_before(created_at_or_before)
      .select_upvote_score
      .select_my_upvote(my_id)
      .select(*MANUAL_SELECTIONS)
      .order_by_hot_created_at_or_before(created_at_or_before)
      .arrange_serializable do |parent, children|
        {
          **parent.attributes
            .filter { |k| ALLOWED_ATTRIBUTES.include? k.to_sym },
          replies: children,
        }
      end
  end

  def create_params
    params.require(:comment)
      .permit(PERMITTED_PARAMS)
      .merge({
        comment_id: params[:comment_id],
        post_id: params[:post_id]
      })
  end
end
