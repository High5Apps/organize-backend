require "test_helper"

class Api::V1::ModerationEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @items = [ballots(:three), comments(:two), posts(:three), users(:seven)]
    @item_ids = @items.map { |it| [it.class.name.foreign_key, it.id] }
    @event = moderation_events:one
    @event_template = @event.dup

    @user = users(:one)
    setup_test_key(@user)
    @authorized_headers = authorized_headers(@user, Authenticatable::SCOPE_ALL)

    @other_user = users(:seven)
    setup_test_key(@other_user)
  end

  test 'should create with valid params' do
    @items.each do |item|
      params = create_params(item)

      assert_difference 'ModerationEvent.count', 1 do
        post api_v1_moderation_events_url, params:, headers: @authorized_headers

        assert_response :created
        assert_pattern { response.parsed_body => id: String, **nil }
      end
    end
  end

  test 'should not create with invalid authorization' do
    @items.each do |item|
      params = create_params(item)

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
    assert_not @other_user.can? :moderate

    @items.each do |item|
      params = create_params(item)

      assert_no_difference 'ModerationEvent.count' do
        post api_v1_moderation_events_url,
          params:,
          headers: authorized_headers(@other_user, Authenticatable::SCOPE_ALL)

        assert_response :unauthorized
      end
    end
  end

  private

  def create_params(item)
    @event.destroy! if @event
    @event_template.item = item
    { moderation_event: @event_template.as_json }
  end
end
