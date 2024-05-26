require "test_helper"

class ModerationEventTest < ActiveSupport::TestCase
  setup do
    @event = moderation_events :one
    @moderatables = [
      ballots(:three), comments(:two), posts(:three), users(:seven),
    ]
  end

  test 'should be valid' do
    moderation_events.each { |event| assert event.valid? }
  end

  test 'action should be present' do
    @event.action = nil
    assert @event.invalid?
  end

  test 'action should be included in actions' do
    @event.action = :bad_action
    assert @event.invalid?
  end

  test 'first action should be allow or block' do
    event = @event.dup
    unblock_all
    assert_empty event.moderatable.moderation_events

    ModerationEvent.actions.keys.each do |action|
      event.action = action
      assert_equal ['allow', 'block'].include?(action), event.valid?
    end
  end

  test 'action after allow should be undo_allow' do
    @event.update action: :allow
    event = @event.dup

    ModerationEvent.actions.keys.each do |action|
      event.action = action
      assert_equal action == 'undo_allow', event.valid?
    end
  end

  test 'action after block should be undo_block' do
    @event.update action: :block
    event = @event.dup

    ModerationEvent.actions.keys.each do |action|
      event.action = action
      assert_equal action == 'undo_block', event.valid?
    end
  end

  test 'action after allow_block or undo_block should be allow or block' do
    [:undo_allow, :undo_block].each do |last_action|
      @event.update action: last_action
      event = @event.dup

      ModerationEvent.actions.keys.each do |action|
        event.action = action
        assert_equal ['allow', 'block'].include?(action), event.valid?
      end
    end
  end

  test 'moderatable should be present' do
    @event.moderatable = nil
    assert @event.invalid?
  end

  test 'moderatable_type should be in ALLOWED_TYPES' do
    @event.moderatable = upvotes :one
    assert @event.invalid?
  end

  test 'moderatable should belong to moderator Org' do
    [
      ballots(:two), comments(:three), posts(:two), users(:five),
    ].each do |moderatable_in_another_org|
      @event.moderatable = moderatable_in_another_org
      assert @event.invalid?
    end
  end

  test 'user should be present' do
    @event.user = nil
    assert @event.invalid?
  end

  test 'non-user moderatables should have previously been flagged at least once' do
    @event.moderatable.flags.destroy_all
    assert @event.invalid?
  end

  test 'user moderatables should not need to be flagged' do
    @event.moderatable = users :seven
    assert @event.valid?
    assert_empty @event.moderatable.flags
    assert @event.valid?
  end

  test 'should not block officers' do
    founder = users :one
    assert founder.terms.active_at(Time.now).any?

    event = @event.dup
    event.moderatable = founder
    assert event.invalid?
  end

  test 'should block moderatable if action is block' do
    event = @event.dup
    unblock_all

    @moderatables.each do |moderatable|
      event.action = :allow
      event.save!

      assert_changes -> { moderatable.reload.blocked }, from: false, to: true do
        event.moderatable = moderatable
        event.action = :block
        event.save!
      end
    end
  end

  test 'should unblock moderatable unless action is block' do
    unblocking_actions = ModerationEvent::actions.keys - ['block']

    event = @event.dup
    unblock_all

    @moderatables.each do |moderatable|
      event.moderatable = moderatable

      unblocking_actions.each do |unblocking_action|
        event.action = :block
        event.save!

        assert_changes -> { moderatable.blocked }, from: true, to: false do
          event.action = unblocking_action
          event.save!
        end
      end
    end
  end

  test 'most_recent_created_at_or_before should contain one moderation_event per moderated moderatable' do
    expected_count = ModerationEvent.group(:moderatable_type, :moderatable_id)
      .count.keys.count
    assert_equal expected_count,
      ModerationEvent.most_recent_created_at_or_before(Time.now).to_a.count
  end

  test 'most_recent_created_at_or_before should not include superceded moderation_events' do
    recent_event_ids = ModerationEvent
      .most_recent_created_at_or_before(Time.now)
      .to_a.map { |me| me[:id] }

    earlier_events = [moderation_events(:undone),  moderation_events(:zero)]
    later_event = moderation_events :one
    earlier_events.each do |earlier_event|
      assert_operator earlier_event.created_at, :<, later_event.created_at
      assert_equal earlier_event.moderatable, later_event.moderatable

      assert_not_includes recent_event_ids, earlier_event.id
    end
  end

  test 'most_recent_created_at_or_before should not include moderation_events created after time' do
    earlier_event = moderation_events :zero
    later_event = moderation_events :one
    assert_operator earlier_event.created_at, :<, later_event.created_at
    assert_equal earlier_event.moderatable, later_event.moderatable

    recent_event_ids = ModerationEvent
      .most_recent_created_at_or_before(earlier_event.created_at)
      .to_a.map { |me| me[:id] }
    assert_not_includes recent_event_ids, later_event.id
    assert_includes recent_event_ids, earlier_event.id
  end

  test 'created_at_or_before should not include moderation_events created after time' do
    event_created_at = moderation_events(:one).created_at
    recent_events = ModerationEvent.created_at_or_before(event_created_at)
    assert_not_equal ModerationEvent.count, recent_events.count
    assert_not_empty recent_events
    recent_events.each do |event|
      assert_operator event.created_at, :<=, event_created_at
    end
  end
end
