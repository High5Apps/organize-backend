class Api::V1::CommentsController < ApplicationController
  ALLOWED_ATTRIBUTES = [
    :blocked,
    :created_at,
    :depth,
    :encrypted_body,
    :id,
    :my_vote,
    :post_id,
    :pseudonym,
    :replies,
    :score,
    :user_id,
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

  def thread
    @comment = authenticated_user.org&.comments&.find params[:id]
    return render_not_found unless @comment

    thread = @comment.path
      .includes_pseudonym
      .with_upvotes_created_at_or_before(Time.now.utc)
      .select_upvote_score
      .select_my_upvote(authenticated_user.id)
      .select(*MANUAL_SELECTIONS)
      .arrange_serializable(&serializer)
      .first

    render json: { thread: }
  end

  private

  def comments
    post = authenticated_user.org&.posts&.find params[:post_id]
    return [] unless post

    now = Time.now

    created_at_or_before_param = params[:created_at_or_before] || now.iso8601(6)
    created_at_or_before = Time.iso8601(created_at_or_before_param.to_s).utc

    my_id = authenticated_user.id

    post.comments
      .created_at_or_before(created_at_or_before)
      .includes_pseudonym
      .with_upvotes_created_at_or_before(created_at_or_before)
      .select_upvote_score
      .select_my_upvote(my_id)
      .select(*MANUAL_SELECTIONS)
      .order_by_hot_created_at_or_before(created_at_or_before)
      .arrange_serializable(&serializer)
  end

  def create_params
    params.require(:comment)
      .permit(PERMITTED_PARAMS)
      .merge({
        parent_id: params[:comment_id],
        post_id: params[:post_id]
      })
  end

  def serializer
    ->(parent, children) {
      {
        **parent.attributes
          .filter { |k| ALLOWED_ATTRIBUTES.include? k.to_sym },
        replies: children,
      }
    }
  end
end
