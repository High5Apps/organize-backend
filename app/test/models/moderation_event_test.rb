require "test_helper"

class ModerationEventTest < ActiveSupport::TestCase
  setup do
    @event = moderation_events :one
    @items = [ballots(:three), comments(:two), posts(:three), users(:seven)]
    @item_ids = @items.map { |it| [it.class.name.foreign_key, it.id] }
    @id_names = @item_ids.map(&:first)
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
end
