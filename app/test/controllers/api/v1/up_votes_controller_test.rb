require "test_helper"

class Api::V1::UpVotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, '*')

    post = posts(:three)
    comment = comments(:two)
    @up_votable_urls = [
      api_v1_post_up_votes_url(post),
      api_v1_comment_up_votes_url(comment),
    ]

    @params = {
      up_vote: {
        value: 1,
      }
    }

    post_up_vote = up_votes(:one)
    assert_not_nil post_up_vote.post

    comment_up_vote = up_votes(:five)
    assert_not_nil comment_up_vote.comment

    @up_votes = [
      post_up_vote,
      comment_up_vote,
    ]
    @up_votes.each do |up_vote|
      assert_equal @user, up_vote.user
      assert_equal @params[:up_vote][:value], up_vote.value
    end

    @up_vote_urls = [
      api_v1_post_up_votes_url(post_up_vote.post),
      api_v1_comment_up_votes_url(comment_up_vote.comment),
    ]
    assert_equal @up_votable_urls.count, @up_vote_urls.count
  end

  test 'should create with valid params' do
    @up_votable_urls.each do |url|
      assert_difference 'UpVote.count', 1 do
        post url, headers: @authorized_headers, params: @params
      end
  
      assert_response :created
    end
  end

  test 'should not create with invalid authorization' do
    @up_votable_urls.each do |url|
      assert_no_difference 'UpVote.count' do
        post url, headers: { Authorization: 'bad'}, params: @params
      end
  
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    @up_votable_urls.each do |url|
      assert_no_difference 'UpVote.count' do
        post url,
          headers: @authorized_headers,
          params: { up_vote: @params[:up_vote].except(:value) }
      end
  
      assert_response :unprocessable_entity
    end
  end

  test 'should not create on a nonexistent up-votable' do
    nonexistent_up_votable_urls = [
      api_v1_post_up_votes_url('non-existent-post-id'),
      api_v1_comment_up_votes_url('non-existent-comment-id'),
    ]
    assert_equal @up_votable_urls.count, nonexistent_up_votable_urls.count

    nonexistent_up_votable_urls.each do |url|
      assert_no_difference 'UpVote.count' do
        post url, headers: @authorized_headers, params: @params
      end
  
      assert_response :not_found
    end
  end

  test 'should not create if up-votable belongs to another Org' do
    post_in_another_org = posts(:two)
    assert_not_equal @user.org, post_in_another_org.org
    comment_in_another_org = comments(:three)
    assert_not_equal @user.org, comment_in_another_org.post.org
    up_votable_urls_in_other_orgs = [
      api_v1_post_up_votes_url(post_in_another_org),
      api_v1_comment_up_votes_url(comment_in_another_org),
    ]
    assert_equal @up_votable_urls.count, up_votable_urls_in_other_orgs.count

    up_votable_urls_in_other_orgs.each do |url|
      assert_no_difference 'UpVote.count' do
        post url, headers: @authorized_headers, params: @params
      end
    end

    assert_response :not_found
  end

  test 'create should not modify a pre-existing up-vote when the value is unchanged' do
    @up_vote_urls.each_with_index do |url, i|
      assert_no_difference 'UpVote.count' do
        assert_no_changes -> { @up_votes[i].reload.updated_at } do
          post url, headers: @authorized_headers, params: @params
        end
      end
  
      assert_response :not_modified
    end
  end

  test 'create should update a pre-existing up-vote when the value is different' do
    @up_vote_urls.each_with_index do |url, i|
      assert_no_difference 'UpVote.count' do
        assert_changes -> { @up_votes[i].reload.updated_at } do
          post url,
            headers: @authorized_headers,
            params: { up_vote: { value: -1 } }
        end
      end
  
      assert_response :ok
    end
  end
end
