class UserQueryTest < ActiveSupport::TestCase
  setup do
    @org = orgs :one
  end

  test 'should respect initial_users' do
    assert_not_equal User.count, @org.users.count
    user_ids = User::Query.new(@org.users).relation.ids
    users = User.find(user_ids)
    assert users.all? { |user| user.org == @org }
  end

  test 'should only include allow-listed attributes' do
    users = User::Query.new(@org.users).relation
    user_json = users.first.as_json.with_indifferent_access

    attribute_allow_list = User::Query::ALLOWED_ATTRIBUTES

    attribute_allow_list.each do |attribute|
      assert user_json.key?(attribute)
    end

    assert_equal attribute_allow_list.count, user_json.keys.count
  end

  test 'should paginate by default' do
    assert User::Query.new(User.all).paginates?
  end

  test 'should not paginate for non-allowlisted filters' do
    filter = 'bad_filter'
    assert_not_includes User::Query::PAGINATION_BYPASSING_FILTERS, filter
    assert User::Query.new(User.all, filter:).paginates?
  end

  test 'should respect joined_at_or_before param' do
    joined_users = User.where.not(joined_at: nil)
    last_user_joined_at = joined_users.order(joined_at: :desc).first.joined_at
    before_last_user_joined = last_user_joined_at - 1.second
    user_ids = User::Query.new(User.all,
      joined_at_or_before: before_last_user_joined.iso8601(6),
    ).relation.ids
    assert_not_equal user_ids.count, joined_users.count
    assert_equal User.joined_at_or_before(before_last_user_joined).ids.sort,
      user_ids.sort
  end

  test 'should user query param to search by pseudonym' do
    respectable_tortoise = users :three
    top_match_id = User::Query.new(User.all, query: 'spectable').relation
      .ids.first
    assert_equal respectable_tortoise.id, top_match_id
  end

  test 'officer filter should match officer scope' do
    expected_user_ids = User.with_service_stats.officers.ids
    assert_not_empty expected_user_ids
    user_ids = User::Query.new(User.all, filter: 'officer').relation.ids
    assert_equal expected_user_ids.sort, user_ids.sort
  end

  test 'officer filter should not paginate' do
    assert_not User::Query.new(User.all, filter: 'officer').paginates?
  end

  test 'office sort should sort by min_office' do
    now = Time.now
    expected_users = @org.users.with_service_stats(now).order_by_office(now)
    users = User::Query.new(@org.users,
      joined_at_or_before: now.iso8601(6),
      sort: 'office',
    ).relation
    assert_equal expected_users.map(&:id), users.map(&:id)
  end

  test 'service sort should use order_by_service' do
    now = Time.now
    expected_users = @org.users.with_service_stats(now).order_by_service(now)
    users = User::Query.new(@org.users,
      joined_at_or_before: now.iso8601(6),
      sort: 'service',
    ).relation
    assert_equal expected_users.map(&:id), users.map(&:id)
  end
end
