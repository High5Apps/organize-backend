require "test_helper"

class ModerationEventTest < ActiveSupport::TestCase
  setup do
    @event = moderation_events :one
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
    items = [
      ['ballot_id', ballots(:three).id],
      ['comment_id', comments(:two).id],
      ['post_id', posts(:three).id],
      ['user_id', users(:seven).id],
    ]
    id_names = items.map(&:first)

    (1 + items.count).times do |n|
      items.combination(n) do |combination|
        id_names.each { |id_name| @event[id_name] = nil }
        combination.each { |id_name, item| @event[id_name] = item }
        assert @event.invalid? unless n == 1
        assert @event.valid? if n == 1
      end
    end
  end
end
