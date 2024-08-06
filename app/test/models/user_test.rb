require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @founder = @user
    @user_without_org = users(:two)
    @enthusiastic_toucan = users(:six)
    @non_founder = users :three
    @user_in_another_org = users(:five)
  end

  test 'should be valid' do
    assert @user.valid?
    assert @user_without_org.valid?
    assert @enthusiastic_toucan.valid?
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

  test 'recruiter should be optional' do
    assert_not_nil @non_founder.recruiter
    assert @non_founder.valid?

    assert_nil @founder.recruiter
    assert @founder.valid?
  end

  test 'recruiter should be in the same Org as User for non-founders' do
    assert_not_equal @non_founder.org, @user_in_another_org.org
    @non_founder.recruiter = @user_in_another_org
    assert @non_founder.invalid?
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

  test 'blocked should only include blocked users' do
    blocked_users = User.blocked
    assert_not_empty blocked_users
    assert_not blocked_users.exists?(blocked: false)
  end

  test 'left_org should only include users who left their Orgs' do
    users_who_left_their_orgs = User.left_org
    assert_not_empty users_who_left_their_orgs
    assert_not users_who_left_their_orgs.exists?(left_org_at: nil)
  end

  test 'omit_left_org should not include users who left their Orgs' do
    non_leavers = User.omit_left_org
    assert_not_equal User.count, non_leavers.count
    assert_not non_leavers.where.not(left_org_at: nil).exists?
  end

  test "my_vote_candidate_ids should return user's vote's candidate_ids" do
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

  test 'officers should contain all active officers' do
    now = Time.now
    org = @user.org
    expected_officer_ids = org.terms.active_at(now).pluck(:user_id).uniq
    officer_ids = org.users.with_service_stats(now).officers.to_a.map(&:id)
    assert_equal expected_officer_ids.sort, officer_ids.sort
  end

  test 'order_by_office should sort by min_office, breaking ties by lowest user_id' do
    now = Time.now

    # This is needed because sort_by can't compare nil values
    higherThanLowestOffice = Office::TYPE_SYMBOLS.count
    expected_users = User.with_service_stats(now)
      .sort_by do |user|
        [user.min_office || higherThanLowestOffice, user.id]
      end
    users = User.with_service_stats(now).order_by_office(now)
    assert_equal expected_users.map(&:id), users.map(&:id)
  end

  test 'order_by_service should not reduce the number of users' do
    now = Time.now
    assert_equal @user.org.users.count,
      @user.org.users.with_service_stats(now).order_by_service(now).to_a.count
  end

  test 'order_by_service should match sort_by_service' do
    now = Time.now
    orgs.each do |org|
      users = org.users
      expected_ordered_users = sort_by_service(users, now)
      ordered_users = users.with_service_stats.order_by_service(now)
      assert_equal expected_ordered_users.map(&:id), ordered_users.map(&:id)
    end
  end

  test 'order_by_service should break ties by highest user_id' do
    now = Time.now
    org = @user.org
    users = org.users
    users.update_all(joined_at: now, recruiter_id: nil)
    assert_not_empty users
    assert_empty users.where.not(joined_at: now)
    assert_empty users.where.not(recruiter_id: nil)
    Connection.destroy_all
    assert_empty Connection.all

    ordered_users = users.with_service_stats.order_by_service(now)
    assert_equal users.order(id: :desc).ids, ordered_users.map(&:id)
  end

  test 'with_service_stats should include offices in the relation' do
    now = Time.now
    expected_offices = @user.org.users.joins(:terms).merge(Term.active_at now)
      .group(:id).pluck(:id, 'array_agg(terms.office) AS offices').to_h
    users_with_offices = @user.org.users.with_service_stats(now)
    users_with_offices.each do |user|
      assert_not_nil user.id
      assert_equal expected_offices[user.id] || [], user.office_numbers
    end
  end

  test 'with_service_stats should not include offices inactive at time' do
    office = :trustee
    assert_empty @user.org.terms.where(office:)

    term = terms(:three).dup
    term.save! # Needed because starts_at/ends_at is set from ballot on create
    term.office = office
    travel_to 2.seconds.ago do
      term.created_at = Time.now
      term.updated_at = Time.now
      term.starts_at = 1.second.from_now
      term.save!
    end

    office_index = Office::TYPE_SYMBOLS.index office

    at_term_start = @user.org.users.with_service_stats(term.starts_at)
    assert_includes at_term_start.flat_map(&:office_numbers), office_index

    before_term_start = @user.org.users
      .with_service_stats(term.starts_at - 1.second)
    assert_not_includes before_term_start.flat_map(&:office_numbers),
      office_index

    before_term_end = @user.org.users
      .with_service_stats(term.ends_at - 1.second)
    assert_includes before_term_end.flat_map(&:office_numbers), office_index

    at_term_end = @user.org.users.with_service_stats(term.ends_at)
    assert_not_includes at_term_end.flat_map(&:office_numbers),
      office_index
  end

  test 'with_service_stats should include min_office in the relation' do
    users_with_min_office = User.with_service_stats
    users_with_min_office.each do |user|
      if user.offices.blank?
        assert_nil user.min_office
      else
        assert_equal user.office_numbers.min, user.min_office
      end
    end
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

  test 'search_by_pseudonym should match full name' do
    assert_equal @enthusiastic_toucan,
      User.search_by_pseudonym('Enthusiastic Toucan').first
  end

  test 'search_by_pseudonym should be case insensitive' do
    assert_equal @enthusiastic_toucan,
      User.search_by_pseudonym('enthusiastic toucan').first
  end

  test 'search_by_pseudonym should not require both first and last name' do
    assert_equal @enthusiastic_toucan,
      User.search_by_pseudonym('enthusiastic').first

    assert_equal @enthusiastic_toucan,
      User.search_by_pseudonym('toucan').first
  end

  test 'search_by_pseudonym should match prefix when long enough' do
    assert_equal @enthusiastic_toucan,
      User.search_by_pseudonym('enthusiast').first
  end

  test 'search_by_pseudonym should not require prefixes to match' do
    assert_equal @enthusiastic_toucan,
      User.search_by_pseudonym('nthusias ouca').first
  end

  test 'can? should match Permission.can' do
    Permission::SCOPE_SYMBOLS.each do |scope|
      assert_equal @user.can?(scope), Permission.can?(@user, scope)
    end
  end

  test 'leave_org should corrupt the ciphertext and auth_tag of non-nil comments and posts' do
    associations = [@user.comments, @user.posts]

    [
      ->(expected, actual) { assert_not_equal expected, actual },
      ->(expected, actual) { assert_equal expected, actual },
    ].each do |assertion|
      associations.each do |association|
        assert_not_empty association.reload
        association.each do |record|
          record.encrypted_attributes.each do |encrypted_attribute|
            encrypted_message = record[encrypted_attribute]
            next if encrypted_message.blank?

            assertion.call User::CORRUPTED_AUTH_TAG_VALUE, encrypted_message.t
            assertion.call User::CORRUPTED_CIPHERTEXT_VALUE, encrypted_message.c
          end
        end
      end

      @user.leave_org
    end
  end

  test 'leave_org should not change nil encrypted_messages' do
    post_without_body = posts :three
    lam = -> { post_without_body.reload.encrypted_body_before_type_cast }
    assert_no_changes lam, from: nil do
      post_without_body.user.leave_org
    end
  end

  test 'leave_org should not change the nonce' do
    post = posts :one
    assert_not_nil post.encrypted_title.nonce
    assert_no_changes -> { post.reload.encrypted_title.nonce } do
      post.user.leave_org
    end
  end

  test 'leave_org should deactivate any active terms' do
    freeze_time do
      assert_not_empty @user.terms.active_at(Time.now)
      @user.leave_org
      assert_empty @user.terms.active_at(Time.now)
    end
  end

  test 'leave_org should set left_org_at to the current time' do
    freeze_time do
      assert_changes -> { @user.reload.left_org_at }, from: nil, to: Time.now do
        @user.leave_org
      end
    end
  end

  test 'leave_org should no-op on successive runs' do
    @user.leave_org

    assert_no_changes -> { @user.reload.left_org_at } do
      travel 1.second
      @user.leave_org
    end
  end

  test 'leave_org should not be allowed when user is not in an Org' do
    @user.update! org: nil
    assert_raises(ActiveRecord::RecordInvalid) { @user.leave_org }
  end

  test 'leave_org should rollback changes to comments and posts if anything goes wrong' do
    @user.update! org: nil
    assert_no_changes -> { @user.posts.first.reload.as_json } do
      assert_no_changes -> { @user.comments.first.reload.as_json } do
        @user.leave_org
        rescue
      end
    end
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

  def sort_by_service(relation, time)
    expected_ordered_users = relation.with_service_stats(time)
      .sort_by do |u|
        tenureInMonths = ((time - u.joined_at) / 1.month)
        [tenureInMonths + u.connection_count + 3 * u.recruit_count, u.id]
      end
      .reverse # Reverse because sort_by uses an ascending sort
  end
end
