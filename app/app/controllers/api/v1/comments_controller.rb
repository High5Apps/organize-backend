class Api::V1::CommentsController < ApplicationController
  ALLOWED_ATTRIBUTES = [
    :id,
    :body,
    :user_id,
    :created_at,
    :pseudonym,
    :score,
    :my_vote,
  ].freeze

  MANUAL_SELECTIONS = ALLOWED_ATTRIBUTES.filter do |k|
    # These attributes are already included by the includes_* scopes below
    ![:score, :pseudonym, :my_vote].include? k
  end.freeze
  private_constant :MANUAL_SELECTIONS

  PERMITTED_PARAMS = [
    :body,
  ].freeze

  before_action :authenticate_user, only: [:index, :create]
  before_action :check_post_belongs_to_org, only: [:index, :create]

  def create
    new_comment = \
      @post.comments.build(create_params.merge(user_id: authenticated_user.id))
    if new_comment.save
      render json: { id: new_comment.id }, status: :created
    else
      render_error :unprocessable_entity, new_comment.errors.full_messages
    end
  end

  def index
    created_before_param = params[:created_before] || Upvote::FAR_FUTURE_TIME
    created_before = Time.at(created_before_param.to_f).utc

    my_id = authenticated_user.id
    comments = @post.comments
      .created_before(created_before)
      .includes_pseudonym
      .includes_score_from_upvotes_created_before(created_before)
      .includes_my_vote_from_upvotes_created_before(created_before, my_id)
      .left_outer_joins_with_most_recent_upvotes_created_before(created_before)
      .select(*MANUAL_SELECTIONS)
      .order_by_hot_created_before(created_before)
    render json: { comments: comments }
  end

  private

  def check_post_belongs_to_org
    @post = Post.find_by id: params[:post_id]
    unless @post&.org == authenticated_user.org
      render_error :not_found, ['Post not found']
    end
  end

  def create_params
    params.require(:comment).permit(PERMITTED_PARAMS)
  end
end
