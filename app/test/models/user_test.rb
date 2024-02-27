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

  test 'joined_before should include users where joined_at is in the past' do
    u1, u2, u3 = create_users_with_joined_at(
      [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now])
    query = User.joined_before u2.joined_at
    assert query.exists? id: u1
    assert_not query.exists? id: u2
    assert_not query.exists? id: u3
  end

  test 'with_seniority_stats should include offices in the relation' do
    expected_offices = @user.org.users.joins(:terms).group(:id)
      .pluck(:id, 'array_agg(terms.office) AS offices').to_h
    users_with_offices = @user.org.users.with_seniority_stats
    users_with_offices.each do |user|
      assert_not_nil user.id
      assert_equal expected_offices[user.id] || [], user.offices
    end
  end

  test 'with_seniority_stats should include the recruit_count in the relation' do
    expected_recruit_counts = @user.org.users.joins(:recruits).group(:id).count
    users_with_recruit_counts = @user.org.users.with_seniority_stats
    users_with_recruit_counts.each do |user|
      assert_not_nil user.id
      assert_equal expected_recruit_counts[user.id] || 0, user.recruit_count
    end
  end

  test 'with_seniority_stats recruit_count should sum to (member count - 1) for an org' do
    orgs.each do |org|
      assert_equal org.users.count - 1,
        org.users.with_seniority_stats.sum(:recruit_count)
    end
  end

  test 'with_seniority_stats should include connection_count in the relation' do
    scanned_counts = @user.org.users.joins(:scanned_connections).group(:id).count
    shared_counts = @user.org.users.joins(:shared_connections).group(:id).count

    users_with_counts = @user.org.users.with_seniority_stats
    users_with_counts.each do |user|
      assert_not_nil user.id
      expected_count = \
        (scanned_counts[user.id] || 0) + (shared_counts[user.id] || 0)
      assert_equal expected_count, user.connection_count
    end
  end

  private

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
