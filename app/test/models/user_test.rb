require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user_without_org = users(:two)
  end

  test 'should be valid' do
    assert @user.valid?
  end

  test 'org should be optional' do
    assert_nil @user_without_org.org
    assert @user_without_org.valid?
  end

  test 'public_key_bytes should be present' do
    @user.public_key_bytes = nil
    assert_not @user.valid?
  end

  test 'public_key_bytes should have the correct length' do
    @user.public_key_bytes = Base64.decode64('deadbeef')
    assert_not @user.valid?
  end

  test 'should set pseudonym when org_id is initially set' do
    assert_nil @user_without_org.pseudonym
    @user_without_org.update!(org: orgs(:one))
    assert_not_nil @user_without_org.reload.pseudonym
  end

  test 'should set joined_at when org_id is initially set' do
    assert_nil @user_without_org.joined_at
    @user_without_org.update!(org: orgs(:one))
    assert_not_nil @user_without_org.reload.joined_at
  end

  test 'should create a founder term when org is created and set on creator' do
    org = orgs :one
    @user_without_org.create_org org.attributes.except 'id'
    assert_difference 'Term.count', 1 do
      @user_without_org.save
    end
  end

  test "my_vote_candidate_ids should return user's most recently created vote's candidate_ids" do
    ballot_with_vote = ballots(:one)
    my_vote_candidate_ids = @user.my_vote_candidate_ids(ballot_with_vote)
    assert_equal votes(:one).candidate_ids, my_vote_candidate_ids
  end

  test 'my_vote_candidate_ids should return [] when user has not voted on ballot' do
    ballot_without_vote = ballots(:three)
    assert_equal [], @user.my_vote_candidate_ids(ballot_without_vote)
  end

  test 'joined_at_or_before should not include users where joined_at is after time' do
    u1, u2, u3 = create_users_with_joined_at(
      [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now])
    query = User.joined_at_or_before u2.joined_at
    assert query.exists? id: u1
    assert query.exists? id: u2
    assert_not query.exists? id: u3
  end

  test 'with_service_stats should include offices in the relation' do
    now = Time.now
    expected_offices = @user.org.users.joins(:terms).merge(Term.active_at now)
      .group(:id).pluck(:id, 'array_agg(terms.office) AS offices').to_h
    users_with_offices = @user.org.users.with_service_stats(now)
    users_with_offices.each do |user|
      assert_not_nil user.id
      assert_equal expected_offices[user.id] || [], user.offices
    end
  end

  test 'with_service_stats should not include offices inactive at time' do
    assert_empty @user.org.terms.trustee
    term = @user.terms.build(office: :trustee, ends_at: 1.minute.from_now)
    term.save!(validate: false)
    trustee_index = Office::TYPE_SYMBOLS.index :trustee

    at_term_creation = @user.org.users.with_service_stats(term.created_at)
    assert_includes at_term_creation.flat_map(&:offices), trustee_index

    before_term_creation = @user.org.users
      .with_service_stats(term.created_at - 1.second)
    assert_not_includes before_term_creation.flat_map(&:offices), trustee_index

    before_term_end = @user.org.users
      .with_service_stats(term.ends_at - 1.second)
    assert_includes before_term_end.flat_map(&:offices), trustee_index

    at_term_end = @user.org.users.with_service_stats(term.ends_at)
    assert_not_includes before_term_creation.flat_map(&:offices), trustee_index
  end

  test 'with_service_stats should include the recruit_count in the relation' do
    now = Time.now
    expected_recruit_counts = @user.org.users.joins(:recruits)
      .where(recruits: { joined_at: ..now }).group(:id).count
    users_with_recruit_counts = @user.org.users.with_service_stats(now)
    users_with_recruit_counts.each do |user|
      assert_not_nil user.id
      assert_equal expected_recruit_counts[user.id] || 0, user.recruit_count
    end
  end

  test 'with_service_stats should not include recruits created after time' do
    after_user_seven_joined = \
      @user.org.users.with_service_stats(users(:seven).joined_at)
    recruiter = after_user_seven_joined.find users(:three).id
    recruit_count = recruiter.recruit_count

    before_user_seven_joined = \
      @user.org.users.with_service_stats(users(:seven).joined_at - 1.second)
    recruiter = before_user_seven_joined.find users(:three).id
    assert_equal -1, recruiter.recruit_count - recruit_count
  end

  test 'with_service_stats recruit_count should sum to (member count - 1) for an org' do
    orgs.each do |org|
      assert_equal org.users.count - 1,
        org.users.with_service_stats.sum(:recruit_count)
    end
  end

  test 'with_service_stats should include connection_count in the relation' do
    now = Time.now
    scanned_counts = @user.org.users.joins(:scanned_connections)
      .merge(Connection.created_at_or_before now).group(:id).count
    shared_counts = @user.org.users.joins(:shared_connections)
      .merge(Connection.created_at_or_before now).group(:id).count

    users_with_counts = @user.org.users.with_service_stats(now)
    users_with_counts.each do |user|
      assert_not_nil user.id
      expected_count = \
        (scanned_counts[user.id] || 0) + (shared_counts[user.id] || 0)
      assert_equal expected_count, user.connection_count
    end
  end

  test 'with_service_stats should not include shared_connections created after time' do
    correct_connection_created_ats_to_match_user_joined_ats

    connection = connections(:three)
    at_connection = @user.org.users.with_service_stats(connection.created_at)
    sharer = at_connection.find connection.sharer.id
    connection_count = sharer.connection_count

    before_connection = \
      @user.org.users.with_service_stats(connection.created_at - 1.second)
    sharer = before_connection.find connection.sharer.id
    assert_equal -1, sharer.connection_count - connection_count
  end

  test 'with_service_stats should not include scanned_connections created after time' do
    correct_connection_created_ats_to_match_user_joined_ats

    connection = connections(:three)
    at_connection = @user.org.users.with_service_stats(connection.created_at)
    scanner = at_connection.find connection.scanner.id
    connection_count = scanner.connection_count

    before_connection = \
      @user.org.users.with_service_stats(connection.created_at - 1.second)
    scanner = before_connection.find connection.scanner.id
    assert_equal -1, scanner.connection_count - connection_count
  end

  private

  def correct_connection_created_ats_to_match_user_joined_ats
    # Without this, connection fixture created_ats are all automatically and
    # incorrectly set to be the fixture creation time
    connections.each do |connection|
      connection.update! created_at: connection.scanner.joined_at
    end
  end

  def create_users_with_joined_at(joined_ats)
    public_key_bytes = users(:one).public_key_bytes
    org = orgs(:one).dup
    org.save!

    joined_ats.map do |joined_at|
      travel_to joined_at do
        user = User.create!(public_key_bytes:)
        user.update!(org:)
        user
      end
    end
  end
end
