class Api::V1::CommentsController < ApplicationController
  INDEX_ATTRIBUTE_ALLOW_LIST = [
    :id,
    :body,
    :user_id,
    :created_at,
    :pseudonym,
  ]

  PERMITTED_PARAMS = [
    :body,
  ]

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
    created_before_param = params[:created_before] || UpVote::FAR_FUTURE_TIME
    created_before = Time.at(created_before_param.to_f).utc

    comments = @post.comments
      .created_before(created_before)
      .joins(:user)
      .order(created_at: :desc)
      .select(*INDEX_ATTRIBUTE_ALLOW_LIST)
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
