require "test_helper"

class FlaggedItemTest < ActiveSupport::TestCase
  setup do
    @flagged_item = flagged_items :one
    @flaggables = [ballots(:three), comments(:two), posts(:three)]
  end

  test 'should be valid' do
    flagged_items.each { |flagged_item| assert flagged_item.valid? }
  end

  test 'flaggable should be present' do
    @flagged_item.flaggable = nil
    assert @flagged_item.invalid?
  end

  test 'user should be present' do
    @flagged_item.user = nil
    assert @flagged_item.invalid?
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
    flagged_item = @flagged_item.dup
    flagged_item.flaggable = election
    assert flagged_item.invalid?
  end

  test 'should not allow candidacy announcements to be flagged' do
    candidacy_announcement = posts :candidacy_announcement
    flagged_item = @flagged_item.dup
    flagged_item.flaggable = candidacy_announcement
    assert flagged_item.invalid?
  end

  test 'flaggable should belong to user Org' do
    item_in_another_org = ballots :two
    assert_not_equal item_in_another_org.org, @flagged_item.user.org
    @flagged_item.flaggable = item_in_another_org
    assert @flagged_item.invalid?
  end

  test 'creator should belong to an Org' do
    user_without_org = users :two
    assert_nil user_without_org.org
    @flagged_item.user = user_without_org
    assert @flagged_item.invalid?
  end

  test 'created_at_or_before should include flagged_items where created_at is not after time' do
    [
      [@flagged_item.created_at - 1.second, false],
      [@flagged_item.created_at, true],
      [@flagged_item.created_at + 1.second, true],
    ].each do |query_time, expect_exists|
      query = FlaggedItem.created_at_or_before(query_time)
      assert_equal expect_exists, query.exists?(id: @flagged_item.id)
    end
  end
end
