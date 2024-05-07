require "test_helper"

class FlaggedItemTest < ActiveSupport::TestCase
  setup do
    @item = flagged_items :one
  end

  test 'should be valid' do
    flagged_items.each { |item| assert item.valid? }
  end

  test 'user should be present' do
    @item.user = nil
    assert @item.invalid?
  end

  test 'should have exactly one item' do
    items = [
      ['ballot_id', ballots(:three).id],
      ['comment_id', comments(:two).id],
      ['post_id', posts(:three).id],
    ]
    id_names = items.map(&:first)

    (1 + items.count).times do |n|
      items.combination(n) do |combination|
        id_names.each { |id_name| @item[id_name] = nil }
        combination.each { |id_name, item| @item[id_name] = item }
        assert @item.invalid? unless n == 1
        assert @item.valid? if n == 1
      end
    end
  end

  test 'should not allow users to double flag the same item' do
    flagged_items.each do |item|
      assert_no_difference 'FlaggedItem.count' do
        assert_raises do
          duplicate = item.dup
          assert_not duplicate.save
        end
      end
    end
  end

  test 'should not allow elections to be flagged' do
    election = ballots :election_one
    flagged_item = @item.dup
    flagged_item.ballot = election
    assert flagged_item.invalid?
  end

  test 'should not allow candidacy announcements to be flagged' do
    candidacy_announcement = posts :candidacy_announcement
    flagged_item = @item.dup
    flagged_item.ballot = nil
    flagged_item.post = candidacy_announcement
    assert flagged_item.invalid?
  end

  test 'created_at_or_before should include flagged_items where created_at is not after time' do
    [
      [@item.created_at - 1.second, false],
      [@item.created_at, true],
      [@item.created_at + 1.second, true],
    ].each do |query_time, expect_exists|
      query = FlaggedItem.created_at_or_before(query_time)
      assert_equal expect_exists, query.exists?(id: @item.id)
    end
  end
end
