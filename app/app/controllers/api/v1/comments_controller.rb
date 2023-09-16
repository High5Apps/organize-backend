class Api::V1::CommentsController < ApplicationController
  ALLOWED_ATTRIBUTES = {
    id: '',
    body: '',
    user_id: '',
    created_at: '',
    pseudonym: '',
    score: '',
    my_vote: '',
  }

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
      .joins(%Q(
        LEFT OUTER JOIN (
          #{UpVote.most_recent_created_before(created_before).to_sql}
        ) AS up_votes
          ON up_votes.comment_id = comments.id
      ).gsub(/\s+/, ' '))
      .order(created_at: :desc)
      .group(:id, :pseudonym)
      .select(*selections)
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

  def selections()
    score = 'COALESCE(SUM(value), 0) AS score'

    # Even though there is at most one most_recent_upvote per requester per
    # comment, SUM is used because an aggregate function is required
    my_vote = Comment.sanitize_sql_array([
      "SUM(CASE WHEN up_votes.user_id = :requester_id THEN value ELSE 0 END) AS my_vote",
      requester_id: authenticated_user.id])

    attributes = ALLOWED_ATTRIBUTES.merge(score: score, my_vote: my_vote)
    attributes.map { |k,v| (v.blank?) ? k : v }
  end
end
