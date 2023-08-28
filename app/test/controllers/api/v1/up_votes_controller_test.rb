require "test_helper"

class Api::V1::UpVotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, '*')

    post = posts(:three)
    comment = comments(:two)
    @commentable_urls = [
      api_v1_post_up_votes_url(post),
      api_v1_comment_up_votes_url(comment),
    ]

    @nonexistent_commentable_urls = [
      api_v1_post_up_votes_url('non-existent-post-id'),
      api_v1_comment_up_votes_url('non-existent-comment-id'),
    ]

    @post_in_another_org = posts(:two)
    assert_not_equal @user.org, @post_in_another_org.org
    @comment_in_another_org = comments(:three)
    assert_not_equal @user.org, @comment_in_another_org.post.org
    @commentable_urls_in_other_orgs = [
      api_v1_post_up_votes_url(@post_in_another_org),
      api_v1_comment_up_votes_url(@comment_in_another_org),
    ]

    @params = {
      up_vote: {
        value: 1,
      }
    }
  end

  test 'should create with valid params' do
    @commentable_urls.each do |url|
      assert_difference 'UpVote.count', 1 do
        post url, headers: @authorized_headers, params: @params
      end
  
      assert_response :created
  
      json_response = JSON.parse(response.body, symbolize_names: true)
      assert_not_nil json_response.dig(:id)
    end
  end

  test 'should not create with invalid authorization' do
    @commentable_urls.each do |url|
      assert_no_difference 'UpVote.count' do
        post url, headers: { Authorization: 'bad'}, params: @params
      end
  
      assert_response :unauthorized
    end
  end

  test 'should not create with invalid params' do
    @commentable_urls.each do |url|
      assert_no_difference 'UpVote.count' do
        post url,
          headers: @authorized_headers,
          params: { up_vote: @params[:up_vote].except(:value) }
      end
  
      assert_response :unprocessable_entity
    end
  end

  test 'should not create on a nonexistent commentable' do
    assert_equal @commentable_urls.count, @nonexistent_commentable_urls.count

    @nonexistent_commentable_urls.each do |url|
      assert_no_difference 'UpVote.count' do
        post url, headers: @authorized_headers, params: @params
      end
  
      assert_response :not_found
    end
  end

  test 'should not create if commentable belongs to another Org' do
    assert_equal @commentable_urls.count, @commentable_urls_in_other_orgs.count

    @commentable_urls_in_other_orgs.each do |url|
      assert_no_difference 'UpVote.count' do
        post url, headers: @authorized_headers, params: @params
      end
    end

    assert_response :not_found
  end
end
