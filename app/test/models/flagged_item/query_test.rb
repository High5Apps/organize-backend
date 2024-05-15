class FlaggedItemQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'should respect initial_posts' do
    org = @user.org
    assert_not_equal FlaggedItem.count, org.flagged_items.count
    query = FlaggedItem::Query.new org.flagged_items
    user_ids = query.flag_reports.map {|f| f[:user_id] }
    users = User.find(user_ids)
    assert users.all? { |user| user.org == org }
  end

  test 'should only include expected attributes' do
    query = FlaggedItem::Query.new FlaggedItem.all
    item = query.flag_reports.first
      .as_json.with_indifferent_access
    assert_pattern do
      item => {
        category: 'Ballot' | 'Comment' | 'Post',
        flag_count: Integer,
        id: String,
        pseudonym: String,
        encrypted_title: {
          c: String,
          n: String,
          t: String,
        },
        user_id: String,
        **nil
      }
    end
  end

  test 'should respect created_at_or_before param' do
    item = flagged_items :two
    query = FlaggedItem::Query.new FlaggedItem.all,
      created_at_or_before: item.created_at

    # The flagged_item aggregates don't have an id or a created_at, so the
    # simplest way to verify is to check that the total flag count of the
    # filtered aggregates equals the number of filtered flagged_item models
    flag_count = query.flag_reports.map { |i| i[:flag_count] }.sum
    assert_not_equal 0, flag_count
    assert_not_equal FlaggedItem.count, flag_count
    assert_equal FlaggedItem.created_at_or_before(item.created_at).count,
      flag_count
  end

  test 'should order posts by top by default' do
    query = FlaggedItem::Query.new FlaggedItem.all
    flag_counts_and_user_ids = query.flag_reports
      .map { |fi| [fi[:flag_count], fi[:flaggable_id]] }

    # Reverse is needed because sort is an ascending sort
    assert_equal flag_counts_and_user_ids.sort.reverse, flag_counts_and_user_ids
  end

  test 'top sort param should order ballots by highest flag count then user_id' do
    query = FlaggedItem::Query.new FlaggedItem.all, sort: 'top'
    flag_counts_and_user_ids = query.flag_reports
      .map { |fi| [fi[:flag_count], fi[:flaggable_id]] }

    # Reverse is needed because sort is an ascending sort
    assert_equal flag_counts_and_user_ids.sort.reverse, flag_counts_and_user_ids
  end
end
