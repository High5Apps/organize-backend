class ModerationEventQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'should respect initial_moderation_events' do
    org = @user.org
    assert_not_equal ModerationEvent.count, org.moderation_events.count
    moderation_events = ModerationEvent::Query.build org.moderation_events
    assert moderation_events.all? { |me| me.user.org == org }
  end

  test 'should only include expected attributes' do
    moderation_events = ModerationEvent::Query.build ModerationEvent.all
    moderation_events.each do |moderation_event|
      assert_pattern do
        moderation_event.as_json.with_indifferent_access => {
          action: String,
          created_at: String,
          id: String,
          moderatable_id: String,
          moderatable_type: String,
          user_id: String,
          user_pseudonym: String,
          **nil
        }
      end
    end
  end

  test 'should respect created_at_or_before param' do
    event = moderation_events :one
    events = ModerationEvent::Query.build ModerationEvent.all,
      created_at_or_before: event.created_at.iso8601(6)
    assert_not_equal ModerationEvent.count, events.to_a.count
    assert_not_empty events
    assert_equal ModerationEvent.created_at_or_before(event.created_at).sort,
      events.sort
  end

  test 'should order by most recently created' do
    event_created_ats = ModerationEvent::Query.build(ModerationEvent.all)
      .pluck(:created_at)
    expected = ModerationEvent.order(created_at: :desc).pluck(:created_at)
    assert_equal expected, event_created_ats
  end

  test 'should order by most recently created regardless of active param' do
    query = ModerationEvent::Query.build ModerationEvent.all, active: true
    event_created_ats = query.pluck :created_at
    assert_operator event_created_ats.count, :>, 1
    event_created_ats.each_cons(2) do |first, second|
      assert_operator first, :>, second
    end
  end

  test 'should filter by actions when param is present' do
    action_names = ModerationEvent.actions.keys
    action_names.count.times do |i|
      combinations = action_names.combination(1 + i)
      combinations.each do |combination|
        query = ModerationEvent::Query.build ModerationEvent.all,
          actions: combination
        assert_not_empty query
        query.to_a.each do |moderation_event|
          assert_includes combination, moderation_event.action
          assert_not_includes (action_names - combination),
            moderation_event.action
        end
      end
    end
  end

  test 'should filter by most_recent_created_at_or_before when active param is true' do
    ids = ModerationEvent::Query.build(ModerationEvent.all, active: true)
      .map { |e| e.id }
    expected_ids = ModerationEvent.most_recent_created_at_or_before(Time.now)
      .order(created_at: :desc)
      .map { |e| e.id }
    assert_equal expected_ids, ids
  end

  test 'should filter by moderatable_type when param is present' do
    ModerationEvent::ALLOWED_TYPES.each do |moderatable_type|
      types = ModerationEvent::Query.build(ModerationEvent.all,
        moderatable_type:
      ).pluck(:moderatable_type).uniq
      assert_equal 1, types.count
      assert_equal moderatable_type, types.first
    end
  end
end
