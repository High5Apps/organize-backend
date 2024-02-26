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
end
