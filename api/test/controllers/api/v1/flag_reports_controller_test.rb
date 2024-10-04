require "test_helper"

class Api::V1::FlagReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)

    @other_user = users(:seven)
    setup_test_key(@other_user)
  end

  test 'should index with valid authorization' do
    get api_v1_flag_reports_url, headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get api_v1_flag_reports_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not index if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_flag_reports_url, headers: @authorized_headers
    assert_response :forbidden
  end

  test 'should not index without permission' do
    assert_not @other_user.can? :moderate
    get api_v1_flag_reports_url,
      headers: authorized_headers(@other_user, Authenticatable::SCOPE_ALL)
    assert_response :forbidden
  end

  test 'index should only include flag reports from requester Org' do
    get api_v1_flag_reports_url, headers: @authorized_headers
    response.parsed_body => flag_reports: flag_report_jsons
    flaggable_creator_ids = flag_report_jsons.map do |flag_report|
      flag_report[:flaggable][:creator][:id]
    end
    assert_not_empty flaggable_creator_ids
    flaggable_creators = User.find flaggable_creator_ids
    flaggable_creators.each do |flaggable_creator|
      assert_equal flaggable_creator.org, @user.org
    end
  end

  test 'index should include pagination metadata' do
    get api_v1_flag_reports_url, headers: @authorized_headers
    assert_contains_pagination_data
  end

  test 'index should respect page param' do
    page = 99
    get api_v1_flag_reports_url,
      headers: @authorized_headers,
      params: { page: }
    pagination_data = assert_contains_pagination_data
    assert_equal page, pagination_data[:current_page]
  end
end
