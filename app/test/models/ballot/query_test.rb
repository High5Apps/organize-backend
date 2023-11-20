class BallotQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'should respect initial_posts' do
    org = @user.org
    assert_not_equal Ballot.count, org.ballots.count
    ballot_ids = Ballot::Query.build({}, initial_ballots: org.ballots).ids
    ballots = Ballot.find(ballot_ids)
    assert ballots.all? { |ballot| ballot.org == org }
  end

  test 'should only include allow-listed attributes' do
    ballots = Ballot::Query.build({}, initial_ballots: @user.org.ballots)
    ballot_json = ballots.first.as_json.with_indifferent_access

    attribute_allow_list = Ballot::Query::ALLOWED_ATTRIBUTES

    attribute_allow_list.each do |attribute|
      assert ballot_json.key?(attribute)
    end

    assert_equal attribute_allow_list.count, ballot_json.keys.count
  end

  test 'should respect created_before param' do
    ballot = ballots(:two)
    ballots = Ballot::Query.build({ created_before: ballot.created_at })
    assert_not_equal Ballot.all.to_a.count, ballots.to_a.count
    assert_equal Ballot.created_before(ballot.created_at).sort, ballots.sort
  end

  test 'should respect active_at param' do
    ballot = ballots(:two)
    ballots = Ballot::Query.build({ active_at: ballot.voting_ends_at })
    assert_not_equal Ballot.all.to_a.count, ballots.to_a.count
    assert_equal Ballot.active_at(ballot.voting_ends_at).sort, ballots.sort
  end

  test 'should respect inactive_at param' do
    ballot = ballots(:two)
    ballots = Ballot::Query.build({ inactive_at: ballot.voting_ends_at })
    assert_not_equal Ballot.all.to_a.count, ballots.to_a.count
    assert_equal Ballot.inactive_at(ballot.voting_ends_at).sort, ballots.sort
  end

  test 'should order posts with newest first by default' do
    voting_ends_ats = Ballot::Query.build.pluck :voting_ends_at
    assert_not_equal 0, voting_ends_ats.count
    assert_equal voting_ends_ats.sort, voting_ends_ats
  end

  test 'should order ballots with voting ending earliest first when sort param is active' do
    voting_ends_ats = Ballot::Query.build({ sort: 'active' })
      .pluck :voting_ends_at
    assert_not_equal 0, voting_ends_ats.count
    assert_equal voting_ends_ats.sort, voting_ends_ats
  end

  test 'should order ballots with voting ending latest first when sort param is inactive' do
    voting_ends_ats = Ballot::Query.build({ sort: 'inactive' })
      .pluck :voting_ends_at

    assert_not_equal 0, voting_ends_ats.count

    # Reverse is needed because sort is an ascending sort
    assert_equal voting_ends_ats.sort.reverse, voting_ends_ats
  end

  test 'sorting by active should be the opposite of sorting by inactive' do
    active = Ballot::Query.build({ sort: 'active' })
    inactive = Ballot::Query.build({ sort: 'inactive' })
    assert_equal active, inactive.reverse
  end
end
