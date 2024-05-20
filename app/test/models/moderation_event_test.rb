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
    ModerationEvent.destroy_all
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

  test 'should block moderatable if action is block' do
    event = @event.dup
    ModerationEvent.destroy_all

    @moderatables.each do |moderatable|
      event.action = :allow
      event.save!

      assert_changes -> { event.reload.moderatable.blocked }, from: false, to: true do
        event.moderatable = moderatable
        event.action = :block
        event.save!
      end
    end
  end

  test 'should unblock moderatable unless action is block' do
    unblocking_actions = ModerationEvent::actions.keys - ['block']

    event = @event.dup
    ModerationEvent.destroy_all

    @moderatables.each do |moderatable|
      event.moderatable = moderatable

      unblocking_actions.each do |unblocking_action|
        event.action = :block
        event.save!

        assert_changes -> { event.reload.moderatable.blocked }, from: true, to: false do
          event.action = unblocking_action
          event.save!
        end
      end
    end
  end
end
