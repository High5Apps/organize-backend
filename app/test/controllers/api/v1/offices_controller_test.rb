require "test_helper"

class Api::V1::OfficesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)
  end

  test 'should index with valid authorization' do
    get api_v1_offices_url, headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get api_v1_offices_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'should not index if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_offices_url, headers: @authorized_headers
    assert_response :not_found
  end

  test 'index response should include all office types except founder' do
    get api_v1_offices_url, headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    office_types = json_response.dig(:offices).map { |o| o[:type] }

    # Subtract 1 because founder shouldn't be present
    assert_equal Office::TYPE_STRINGS.count - 1, office_types.count
    assert_equal Office::TYPE_STRINGS - office_types, ['founder']
  end

  test 'index response open should be accurate' do
    get api_v1_offices_url, headers: @authorized_headers
    json_response = JSON.parse(response.body, symbolize_names: true)
    offices = json_response.dig(:offices)
    expected_filled = ['president', 'secretary']
    offices.each do |office|
      assert_not_equal expected_filled.include?(office[:type]), office[:open]
    end
  end
end
