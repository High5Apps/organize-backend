class BallotQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'should respect initial_posts' do
    org = @user.org
    assert Ballot.where.not(org: org).exists?
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
end
