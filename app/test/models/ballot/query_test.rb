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
end
