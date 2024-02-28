class UserQueryTest < ActiveSupport::TestCase
  setup do
    @org = orgs :one
  end

  test 'should respect initial_users' do
    assert_not_equal User.count, @org.users.count
    user_ids = User::Query.build({}, initial_users: @org.users).ids
    users = User.find(user_ids)
    assert users.all? { |user| user.org == @org }
  end

  test 'should only include allow-listed attributes' do
    users = User::Query.build({}, initial_users: @org.users)
    user_json = users.first.as_json.with_indifferent_access

    attribute_allow_list = User::Query::ALLOWED_ATTRIBUTES

    attribute_allow_list.each do |attribute|
      assert user_json.key?(attribute)
    end

    assert_equal attribute_allow_list.count, user_json.keys.count
  end

  test 'should respect joined_at_or_before param' do
    joined_users = User.where.not(joined_at: nil)
    last_user_joined_at = joined_users.order(joined_at: :desc).first.joined_at
    before_last_user_joined = last_user_joined_at - 1.second
    user_ids = User::Query.build({
      joined_at_or_before: before_last_user_joined,
    }).ids
    assert_not_equal user_ids.count, joined_users.count
    assert_equal User.joined_at_or_before(before_last_user_joined).ids.sort,
      user_ids.sort
  end

  test 'officer filter should match officer scope' do
    expected_user_ids = User.with_service_stats.officers.ids
    assert_not_empty expected_user_ids
    user_ids = User::Query.build({ filter: 'officer' }).ids
    assert_equal expected_user_ids.sort, user_ids.sort
  end

  test 'office sort should sort by min_office' do
    now = Time.now
    expected_users = @org.users.with_service_stats.order(:min_office)
    users = User::Query.build({
      joined_at_or_before: now,
      sort: 'office',
    }, initial_users: @org.users)
    assert_equal expected_users.map(&:id), users.map(&:id)
  end

  test 'service sort should use order_by_service' do
    now = Time.now
    expected_users = @org.users.with_service_stats(now).order_by_service(now)
    users = User::Query.build({
      joined_at_or_before: now,
      sort: 'service',
    }, initial_users: @org.users)
    assert_equal expected_users.map(&:id), users.map(&:id)
  end
end
