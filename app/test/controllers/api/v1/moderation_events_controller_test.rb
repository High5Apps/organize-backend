require "test_helper"

class Api::V1::ModerationEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @moderatables = [
      ballots(:three), comments(:two), posts(:three), users(:seven)
    ]
    @event = moderation_events :one
    @event_template = @event.dup

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)

    @other_user = users(:seven)
    setup_test_key(@other_user)
  end

  test 'should create with valid params' do
    @moderatables.each do |moderatable|
      params = create_params(moderatable)

      assert_difference 'ModerationEvent.count', 1 do
        post api_v1_moderation_events_url, params:, headers: @authorized_headers

        assert_response :created
        assert_pattern { response.parsed_body => id: String, **nil }
      end
    end
  end

  test 'should not create with invalid authorization' do
    @moderatables.each do |moderatable|
      params = create_params(moderatable)

      assert_no_difference 'ModerationEvent.count' do
        post api_v1_moderation_events_url,
          params:,
          headers: authorized_headers(@user,
            Authenticatable::SCOPE_ALL,
            expiration: 1.second.ago)

        assert_response :unauthorized
      end
    end
  end

  test 'should not create without permission' do
    assert_not @other_user.can? :block_users
    assert_not @other_user.can? :moderate

    @moderatables.each do |moderatable|
      params = create_params(moderatable)

      assert_no_difference 'ModerationEvent.count' do
        post api_v1_moderation_events_url,
          params:,
          headers: authorized_headers(@other_user, Authenticatable::SCOPE_ALL)

        assert_response :forbidden
      end
    end
  end

  test 'should index with valid authorization' do
    get api_v1_moderation_events_url, headers: @authorized_headers
    assert_response :ok
  end

  test 'should not index with invalid authorization' do
    get api_v1_moderation_events_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'index should be empty if user is not in an Org' do
    @user.update!(org: nil)
    assert_nil @user.reload.org

    get api_v1_moderation_events_url, headers: @authorized_headers
    assert_pattern { response.parsed_body => moderation_events: [] }
  end

  test 'index should only include moderation events from requester Org' do
    get api_v1_moderation_events_url, headers: @authorized_headers
    moderation_event_ids = get_moderation_event_ids_from_response
    assert_not_empty moderation_event_ids
    moderation_events = ModerationEvent.find(moderation_event_ids)
    moderation_events.each do |moderation_event|
      assert_equal @user.org, moderation_event.user.org
    end
  end

  test 'index should format created_at attributes as iso8601' do
    get api_v1_moderation_events_url, headers: @authorized_headers
    response.parsed_body => moderation_events: [{ created_at: }, *]
    assert Time.iso8601(created_at)
  end

  test 'index should only include expected attributes' do
    get api_v1_moderation_events_url, headers: @authorized_headers
    response.parsed_body => moderation_events:
    moderation_events.each do |moderation_event|
      assert_pattern do
        moderation_event.as_json.with_indifferent_access => {
          action: String,
          created_at: String,
          id: String,
          moderatable: {
            category: String,
            creator: {
              id: String,
              pseudonym: String,
              **nil
            },
            id: String,
            **nil
          },
          moderator: {
            id: String,
            pseudonym: String,
            **nil
          },
        }
      end
    end
  end

  test 'index should include pagination metadata' do
    get api_v1_moderation_events_url, headers: @authorized_headers
    assert_contains_pagination_data
  end

  test 'index should respect page param' do
    page = 99
    get api_v1_moderation_events_url, headers: @authorized_headers,
      params: { page: }
    pagination_data = assert_contains_pagination_data
    assert_equal page, pagination_data[:current_page]
  end

  private

  def create_params(moderatable)
    ModerationEvent.destroy_all
    @event_template.moderatable = moderatable
    { moderation_event: @event_template.as_json }
  end

  def get_moderation_event_ids_from_response
    response.parsed_body => moderation_events: moderation_event_jsons
    moderation_event_jsons.map { |me| me[:id] }
  end
end
