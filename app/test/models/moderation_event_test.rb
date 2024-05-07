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

  test 'moderator should be present' do
    @event.moderator = nil
    assert @event.invalid?
  end

  test 'should have exactly one item' do
    (1 + @item_ids.count).times do |n|
      @item_ids.combination(n) do |combination|
        @id_names.each { |id_name| @event[id_name] = nil }
        combination.each { |id_name, item| @event[id_name] = item }
        assert @event.invalid? unless n == 1
        assert @event.valid? if n == 1
      end
    end
  end

  test 'item should link to the associated item' do
    @item_ids.each do |item|
      @id_names.each { |id_name| @event[id_name] = nil }
      id_name, id = item
      @event[id_name] = id
      assert_equal id, @event.item.id
    end
  end

  test 'item should return nil when no item is set' do
    @event.ballot = nil
    assert_nil @event.item
  end

  test 'item should return nil when multiple items are set' do
    @event.ballot = ballots :three
    @event.comment = comments :two
    assert_nil @event.item
  end

  test 'item= should set the appropriate *_id' do
    @items.each do |item|
      @event.item = item
      assert_equal item, @event.item
    end
  end

  test 'item= should raise for unknown classes' do
    assert_raises do
      @event.item = upvotes :one
    end
  end

  test 'non-user items should have previously be flagged at least once' do
    @event.ballot.flagged_items.destroy_all
    assert @event.invalid?
  end

  test 'user items should not need to be flagged' do
    @event.ballot_id = nil
    @event.user = users :seven
    assert @event.valid?
    assert_empty @event.user.flagged_items
    assert @event.valid?
  end
end
