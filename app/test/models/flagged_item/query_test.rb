class FlaggedItemQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'should respect initial_posts' do
    org = @user.org
    assert_not_equal FlaggedItem.count, org.flagged_items.count
    user_ids = FlaggedItem::Query
      .build({}, initial_flagged_items: org.flagged_items)
      .map {|f| f.user_id }
    users = User.find(user_ids)
    assert users.all? { |user| user.org == org }
  end

  test 'should only include expected attributes' do
    item = FlaggedItem::Query.build({}).first.as_json.with_indifferent_access
    assert_pattern do
      item => {
        ballot_id: String | nil,
        comment_id: String | nil,
        flag_count: Integer,
        id: nil, # This is an artifact of using Rails and non-trivial to remove
        post_id: String | nil,
        pseudonym: String,
        title: {
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
    items = FlaggedItem::Query.build({ created_at_or_before: item.created_at })

    # The flagged_item aggregates don't have an id or a created_at, so the
    # simplest way to verify is to check that the total flag count of the
    # filtered aggregates equals the number of filtered flagged_item models
    flag_count = items.map { |i| i[:flag_count] }.sum
    assert_not_equal 0, flag_count
    assert_not_equal FlaggedItem.count, flag_count
    assert_equal FlaggedItem.created_at_or_before(item.created_at).count,
      flag_count
  end

  test 'should order posts by top by default' do
    flag_counts_and_user_ids = FlaggedItem::Query.build({})
      .map { |fi| [fi[:flag_count], fi[:user_id]] }

    # Reverse is needed because sort is an ascending sort
    assert_equal flag_counts_and_user_ids.sort.reverse, flag_counts_and_user_ids
  end

  test 'top sort param should order ballots by highest flag count then user_id' do
    flag_counts_and_user_ids = FlaggedItem::Query.build({ sort: 'top' })
      .map { |fi| [fi[:flag_count], fi[:user_id]] }

    # Reverse is needed because sort is an ascending sort
    assert_equal flag_counts_and_user_ids.sort.reverse, flag_counts_and_user_ids
  end
end
