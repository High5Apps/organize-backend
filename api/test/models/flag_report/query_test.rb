class FlagReportQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'should only include flaggables from the given org' do
    org = @user.org
    assert_not_equal Flag.count, org.flags.count
    flag_reports = FlagReport::Query.new(org).flag_reports
    user_ids = flag_reports.map { |fr| fr[:flaggable][:creator][:id] }
    assert_not_empty user_ids
    users = User.find(user_ids)
    assert users.all? { |user| user.org == org }
  end

  test 'should only include expected attributes' do
    flag_reports = FlagReport::Query.new(@user.org).flag_reports
    flag_report = flag_reports.each do |flag_report|
      assert_pattern do
        flag_report.as_json.with_indifferent_access => {
          flaggable: {
            category: 'Ballot' | 'Comment' | 'Post',
            creator: {
              id: String,
              pseudonym: String,
              **nil
            },
            deleted_at: String | nil,
            encrypted_title: {
              c: String,
              n: String,
              t: String,
              **nil
            },
            id: String,
            **nil
          },
          flag_count: Integer,
          moderation_event: nil | {
            action: String,
            created_at: String,
            id: String,
            moderator: {
              id: String,
              pseudonym: String,
              **nil
            },
            **nil
          },
          **nil
        }
      end
    end
  end

  test 'should include one flag report per flaggable by default' do
    expected_count = @user.org.flags
      .group(:flaggable_type, :flaggable_id)
      .count.keys.count

    assert_equal expected_count,
      FlagReport::Query.new(@user.org).flag_reports.count
  end

  test 'should respect created_at_or_before param' do
    flag = flags :two
    flag_reports = FlagReport::Query.new(@user.org,
      created_at_or_before: flag.created_at.iso8601(6)
    ).flag_reports

    # The flag aggregates don't have an id or a created_at, so the
    # simplest way to verify is to check that the total flag count of the
    # filtered aggregates equals the number of filtered flag models
    flag_count = flag_reports.map { |fr| fr[:flag_count] }.sum
    assert_not_equal 0, flag_count
    assert_not_equal Flag.count, flag_count
    assert_equal Flag.created_at_or_before(flag.created_at).count,
      flag_count
  end

  test 'should order by most flags by default' do
    flag_reports = FlagReport::Query.new(@user.org).flag_reports
    flag_counts_and_flaggable_ids = flag_reports
      .map { |fr| [fr[:flag_count], fr[:flaggable_id]] }

    # Reverse is needed because sort is an ascending sort
    assert_equal flag_counts_and_flaggable_ids.sort.reverse,
      flag_counts_and_flaggable_ids
  end

  test 'handled=true should order by most recent moderation_event creation' do
    # This ensures there are at least two handled events
    moderation_events(:three).destroy!

    flag_reports = FlagReport::Query.new(@user.org, handled: true).flag_reports
    moderation_event_created_ats  = flag_reports
      .map { |fr| fr[:moderation_event][:created_at] }
    assert_operator moderation_event_created_ats.uniq.count, :>, 1

    moderation_event_created_ats.each_cons(2) do |first, second|
      assert_operator first, :>=, second
    end
  end

  test 'should include all flag reports regardless of moderation status when handled param absent' do
    flag_reports = FlagReport::Query.new(@user.org).flag_reports
    with_events, without_events = get_with_and_without_moderation_events(
      flag_reports)
    assert_not_empty with_events
    assert_not_empty without_events

    with_handled, with_unhandled = get_with_handled_and_unhandled_actions(
      flag_reports)
    assert_not_empty with_handled
    assert_not_empty with_unhandled
  end

  test 'handled=true should only include flag reports with handled moderation event actions' do
    flag_reports = FlagReport::Query.new(@user.org, handled: true).flag_reports
    with_events, without_events = get_with_and_without_moderation_events(
      flag_reports)
    assert_not_empty with_events
    assert_empty without_events

    with_handled, with_unhandled = get_with_handled_and_unhandled_actions(
      flag_reports)
    assert_not_empty with_handled
    assert_empty with_unhandled
  end

  test 'handled=false should only include flag reports without moderation_events or with unhandled moderation event actions' do
    flag_reports = FlagReport::Query.new(@user.org, handled: false).flag_reports
    with_events, without_events = get_with_and_without_moderation_events(
      flag_reports)
    assert_not_empty with_events
    assert_not_empty without_events

    with_handled, with_unhandled = get_with_handled_and_unhandled_actions(
      flag_reports)
    assert_empty with_handled
    assert_not_empty with_unhandled
  end

  test 'flag_count should be correct' do
    # Query sorts by most flags by default
    flag_reports = FlagReport::Query.new(@user.org).flag_reports
    flag_counts = @user.org.flags.group(:flaggable_id, :flaggable_type)
      .count(:flaggable_id).values

    assert_operator flag_counts.uniq.count, :>, 1
    assert_operator flag_counts.max, :>, 1
    assert_operator flag_counts.min, :>, 0

    assert_equal flag_counts.max, flag_reports.first[:flag_count]
  end

  private

  def get_with_handled_and_unhandled_actions(flag_reports)
    with_moderation_events, _ = get_with_and_without_moderation_events(
      flag_reports)
    actions = with_moderation_events.map { |fr| fr[:moderation_event][:action] }

    with_handled = actions.filter do |action|
      !FlagReport::Query::UNHANDLED_ACTIONS.include? action
    end
    with_unhandled = actions.filter do |action|
      FlagReport::Query::UNHANDLED_ACTIONS.include? action
    end

    return [with_handled, with_unhandled]
  end

  def get_with_and_without_moderation_events(flag_reports)
    with = flag_reports.filter { |fr| !fr[:moderation_event].nil? }
    without = flag_reports.filter { |fr| fr[:moderation_event].nil? }
    return [with, without]
  end
end
