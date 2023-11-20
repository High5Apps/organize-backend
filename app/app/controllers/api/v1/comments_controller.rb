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
  before_action :check_commentable_belongs_to_org, only: [:index, :create]

  def create
    new_comment = @commentable_relation.build(create_params)
    if new_comment.save
      render json: { id: new_comment.id }, status: :created
    else
      render_error :unprocessable_entity, new_comment.errors.full_messages
    end
  end

  def index
    created_before_param = params[:created_before] || Upvote::FAR_FUTURE_TIME
    created_before = Time.parse(created_before_param.to_s).utc

    my_id = authenticated_user.id
    comments = @post.comments
      .created_before(created_before)
      .includes_pseudonym
      .includes_score_from_upvotes_created_before(created_before)
      .includes_my_vote_from_upvotes_created_before(created_before, my_id)
      .select(*MANUAL_SELECTIONS)
      .order_by_hot_created_before(created_before)
      .arrange_serializable do |parent, children|
        {
          **parent.attributes
            .filter { |k| ALLOWED_ATTRIBUTES.include? k.to_sym },
          replies: children,
        }
      end
    render json: { comments: comments }
  end

  private

  def check_commentable_belongs_to_org
    post_id = params[:post_id]
    comment_id = params[:comment_id]

    unless post_id || comment_id
      return render_error :bad_request, ['Must include post_id or comment_id']
    end

    if post_id
      @post = Post.find_by id: post_id
      @commentable_relation = @post&.comments
    else
      comment = Comment.includes(:post).find_by id: comment_id
      @post = comment&.post
      @commentable_relation = comment&.children
    end

    user_org = authenticated_user.org
    unless user_org && (@post&.org == user_org)
      render_error :not_found, ['Commentable not found']
    end
  end

  def create_params
    params.require(:comment)
      .permit(PERMITTED_PARAMS)
      .merge(
        # post_id is needed for replies, since the shallow route doesn't include
        # the post_id
        post_id: @post.id,
        user_id: authenticated_user.id)
  end
end
