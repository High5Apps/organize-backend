class FlagReportQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'should respect initial_posts' do
    org = @user.org
    assert_not_equal Flag.count, org.flags.count
    query = FlagReport::Query.new org.flags
    user_ids = query.flag_reports.map {|f| f[:creator][:id] }
    assert_not_empty user_ids
    users = User.find(user_ids)
    assert users.all? { |user| user.org == org }
  end

  test 'should only include expected attributes' do
    query = FlagReport::Query.new Flag.all
    flag_report = query.flag_reports.each do |flag_report|
      assert_pattern do
        flag_report.as_json.with_indifferent_access => {
          category: 'Ballot' | 'Comment' | 'Post',
          creator: {
            id: String,
            pseudonym: String,
          },
          encrypted_title: {
            c: String,
            n: String,
            t: String,
          },
          flag_count: Integer,
          id: String,
          moderation_event: nil | {
            action: String,
            created_at: String,
            moderator: {
              id: String,
              pseudonym: String,
            },
          },
          **nil
        }
      end
    end
  end

  test 'should respect created_at_or_before param' do
    flag = flags :two
    query = FlagReport::Query.new Flag.all,
      created_at_or_before: flag.created_at.iso8601(6)

    # The flag aggregates don't have an id or a created_at, so the
    # simplest way to verify is to check that the total flag count of the
    # filtered aggregates equals the number of filtered flag models
    flag_count = query.flag_reports.map { |i| i[:flag_count] }.sum
    assert_not_equal 0, flag_count
    assert_not_equal Flag.count, flag_count
    assert_equal Flag.created_at_or_before(flag.created_at).count,
      flag_count
  end

  test 'should order posts by top by default' do
    query = FlagReport::Query.new Flag.all
    flag_counts_and_user_ids = query.flag_reports
      .map { |fi| [fi[:flag_count], fi[:flaggable_id]] }

    # Reverse is needed because sort is an ascending sort
    assert_equal flag_counts_and_user_ids.sort.reverse, flag_counts_and_user_ids
  end

  test 'top sort param should order ballots by highest flag count then user_id' do
    query = FlagReport::Query.new Flag.all, sort: 'top'
    flag_counts_and_user_ids = query.flag_reports
      .map { |fi| [fi[:flag_count], fi[:flaggable_id]] }

    # Reverse is needed because sort is an ascending sort
    assert_equal flag_counts_and_user_ids.sort.reverse, flag_counts_and_user_ids
  end
end
