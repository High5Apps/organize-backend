require "test_helper"

class OfficeTest < ActiveSupport::TestCase
  setup do
    @org = orgs :two
    @user = @org.users.first
    @election = ballots :election_one
    @term = terms :three
  end

  test 'availability should include all offices' do
    expected = Office::TYPE_STRINGS
    assert_equal expected.sort, availability_in.map{ |o| o[:type] }.sort
  end

  test 'availability should be open if there is no active term or election' do
    assert_empty @org.ballots.election
    assert_equal ['founder'], @org.terms.pluck(:office)
    assert_availability_open_except_for ['founder']
  end

  test 'availability should not be open if there is an active election' do
    (Office::TYPE_STRINGS - ['founder']).each do |office|
      attributes = @election.attributes.merge \
        id: nil, office:, user_id: @user.id
      ballot = @user.ballots.create! attributes
      assert_availability_open_except_for ['founder', ballot.office]
      ballot.destroy!
    end
  end

  test 'availability for non-stewards should not be open if there is a term outside cooldown' do
    (Office::TYPE_STRINGS - ['founder', 'steward']).each do |office|
      attributes = @term.attributes.merge id: nil, office:, user_id: @user.id
      term = @user.terms.create! attributes
      travel_to term.ends_at - Term::COOLDOWN_PERIOD
      assert_availability_open_except_for ['founder']
      travel -1.second
      assert_availability_open_except_for ['founder', term.office]
      term.destroy!
    end
  end

  test 'availability for stewards should disregard if there is a term outside cooldown' do
    office = 'steward'
    attributes = @term.attributes.merge id: nil, office:, user_id: @user.id
    term = @user.terms.create! attributes
    travel_to term.ends_at - Term::COOLDOWN_PERIOD
    assert_availability_open_except_for ['founder']
    travel -1.second
    assert_availability_open_except_for ['founder']
  end

  private

  def availability_in
    Office.availability_in(@org)
  end

  def assert_availability_open_except_for offices
    assert_equal offices.sort,
      availability_in.filter { |o| !o[:open] }.map { |o| o[:type] }.sort
  end
end
