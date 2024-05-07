require "test_helper"

class FlaggedItemTest < ActiveSupport::TestCase
  setup do
    @flagged_item = flagged_items :one
    @items = [ballots(:three), comments(:two), posts(:three)]
    @item_ids = @items.map { |item| [item.class.name.foreign_key, item.id] }
    @id_names = @item_ids.map(&:first)
  end

  test 'should be valid' do
    flagged_items.each { |item| assert item.valid? }
  end

  test 'user should be present' do
    @flagged_item.user = nil
    assert @flagged_item.invalid?
  end

  test 'should have exactly one item' do
    (1 + @item_ids.count).times do |n|
      @item_ids.combination(n) do |combination|
        @id_names.each { |id_name| @flagged_item[id_name] = nil }
        combination.each { |id_name, item| @flagged_item[id_name] = item }
        assert @flagged_item.invalid? unless n == 1
        assert @flagged_item.valid? if n == 1
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
    flagged_item = @flagged_item.dup
    flagged_item.ballot = election
    assert flagged_item.invalid?
  end

  test 'should not allow candidacy announcements to be flagged' do
    candidacy_announcement = posts :candidacy_announcement
    flagged_item = @flagged_item.dup
    flagged_item.ballot = nil
    flagged_item.post = candidacy_announcement
    assert flagged_item.invalid?
  end

  test 'item should link to the associated item' do
    @item_ids.each do |item|
      @id_names.each { |id_name| @flagged_item[id_name] = nil }
      id_name, id = item
      @flagged_item[id_name] = id
      assert_equal id, @flagged_item.item.id
    end
  end

  test 'item should return nil when no item is set' do
    @flagged_item.ballot = nil
    assert_nil @flagged_item.item
  end

  test 'item should return nil when multiple items are set' do
    @flagged_item.ballot = ballots :three
    @flagged_item.comment = comments :two
    assert_nil @flagged_item.item
  end

  test 'item= should set the appropriate *_id' do
    @items.each do |item|
      @flagged_item.item = item
      assert_equal item, @flagged_item.item
    end
  end

  test 'item= should raise for unknown classes' do
    assert_raises do
      @flagged_item.item = upvotes :one
    end
  end

  test 'item should belong to user Org' do
    item_in_another_org = ballots :two
    assert_not_equal item_in_another_org.org, @flagged_item.user.org
    @flagged_item.item = item_in_another_org
    assert @flagged_item.invalid?
  end

  test 'item should exist' do
    @id_names.each do |id_name|
      @id_names.each { |id_name_inner| @flagged_item[id_name_inner] = nil }
      @flagged_item[id_name] = 'bad-id'
      assert @flagged_item.invalid?
    end
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
