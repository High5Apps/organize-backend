require "test_helper"

class Api::V1::UpVotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, '*')

    @up_vote = up_votes(:one)
    @old_value = @up_vote.value
    @new_value = -1
    assert_not_equal @old_value, @new_value

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

  test 'should update with valid params' do
    assert_changes -> { @up_vote.reload.value }, {
      from: @old_value, to: @new_value,
    } do
      patch api_v1_up_vote_url(@up_vote),
        headers: @authorized_headers,
        params: { up_vote: @params[:up_vote].merge(value: @new_value) }
    end

    assert_response :no_content
  end

  test 'should not update with invalid authorization' do
    assert_no_changes -> { @up_vote.reload.value } do
      patch api_v1_up_vote_url(@up_vote),
        headers: { Authorization: 'bad'},
        params: { up_vote: @params[:up_vote].merge(value: @new_value) }
    end

    assert_response :unauthorized
  end

  test 'should not update with invalid params' do
    assert_no_changes -> { @up_vote.reload.value } do
      patch api_v1_up_vote_url(@up_vote),
        headers: @authorized_headers,
        params: { up_vote: @params[:up_vote].merge(value: 2) }
    end

    assert_response :unprocessable_entity
  end

  test 'should not update when up vote belongs to another user' do
    up_vote_of_another_user = up_votes(:two)
    assert_not_equal @user, up_vote_of_another_user.user
    assert_not_equal up_vote_of_another_user.value, @new_value
    assert_no_changes -> { up_vote_of_another_user.reload.value } do
      patch api_v1_up_vote_url(up_vote_of_another_user),
        headers: @authorized_headers,
        params: { up_vote: @params[:up_vote].merge(value: @new_value) }
    end

    assert_response :not_found
  end

  test 'should ignore unpermitted params and only update permitted params' do
    other_post = posts(:two)
    assert_changes -> { @up_vote.reload.value }, {
      from: @old_value, to: @new_value,
    } do
      assert_no_changes -> { @up_vote.reload.post_id } do
        patch api_v1_up_vote_url(@up_vote),
          headers: @authorized_headers,
          params: {
            up_vote: @params[:up_vote].merge(
              post_id: other_post.id,
              value: @new_value,
            )
          }
      end
    end

    assert_response :no_content
  end
end
