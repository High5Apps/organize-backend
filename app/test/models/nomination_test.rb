require "test_helper"

class NominationTest < ActiveSupport::TestCase
  setup do
    @nomination = nominations :election_one_choice_one
    @other_nomination = nominations :election_one_choice_four
  end

  test 'preconditions' do
    assert_equal @nomination.ballot, @other_nomination.ballot

    # Ensure that no candidate is present for this nomination, which would cause
    # foreign_key constraint violations when destroying the nomination
    assert_not @other_nomination.accepted
  end

  test 'should be valid' do
    assert @nomination.valid?
  end

  test 'accepted should be optional' do
    @nomination.accepted = nil
    assert @nomination.valid?
  end

  test 'ballot should be present' do
    @nomination.ballot = nil
    assert @nomination.invalid?
  end

  test 'nominator should be present' do
    @nomination.nominator = nil
    assert @nomination.invalid?
  end

  test 'nominee should be present' do
    @nomination.nominee = nil
    assert @nomination.invalid?
  end

  test 'should not be able to self-nominate' do
    @nomination.nominee = @nomination.nominator
    assert @nomination.invalid?
  end

  test 'should be able to create multiple nominations per nominator on a ballot' do
    nomination = @other_nomination.dup
    @other_nomination.destroy!
    nomination.nominator = @nomination.nominator
    assert nomination.save
  end

  test 'should not be able to nominate a nominee more than once on a ballot' do
    nomination = @other_nomination.dup
    @other_nomination.destroy!
    nomination.nominee = @nomination.nominee
    assert_not nomination.save
  end
end
