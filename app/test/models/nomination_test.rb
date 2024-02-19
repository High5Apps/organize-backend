require "test_helper"

class NominationTest < ActiveSupport::TestCase
  setup do
    @nomination = nominations :election_one_choice_one
    @rejected_nomination = nominations :election_one_choice_three
    @unaccepted_nomination = nominations :election_one_choice_four
  end

  test 'preconditions' do
    assert_equal @nomination.ballot, @unaccepted_nomination.ballot
    assert_equal true, @nomination.accepted
    assert_equal false, @rejected_nomination.accepted
    assert_nil @unaccepted_nomination.accepted
  end

  test 'should be valid' do
    assert @nomination.valid?
  end

  test 'accepted should be optional' do
    @unaccepted_nomination.accepted = nil
    assert @unaccepted_nomination.valid?
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
    nomination = @unaccepted_nomination.dup
    @unaccepted_nomination.destroy!
    nomination.nominator = @nomination.nominator
    assert nomination.save
  end

  test 'should not be able to nominate a nominee more than once on a ballot' do
    nomination = @unaccepted_nomination.dup
    @unaccepted_nomination.destroy!
    nomination.nominee = @nomination.nominee
    assert_not nomination.save
  end

  test 'should create a candidate for the nominee when nomination is accepted' do
    assert_changes -> {
      @unaccepted_nomination.ballot.candidates
        .exists?(user: @unaccepted_nomination.nominee)
    }, from: false, to: true do
      assert_difference 'Candidate.count', 1 do
        @unaccepted_nomination.update! accepted: true
      end
    end
  end

  test 'should not create a candidate for the nominee when nomination is rejected' do
    assert_no_difference 'Candidate.count' do
      @unaccepted_nomination.update! accepted: false
    end
  end

  test 'should not be able to accept a rejected nomination' do
    assert_not @rejected_nomination.update accepted: true
  end

  test 'should not be able to reject an accepted nomination' do
    assert_not @nomination.update accepted: false
  end

  test 'should not be able to unaccept an accepted nomination' do
    assert_not @nomination.update accepted: nil
  end

  test 'should not be able to unreject a rejected nomination' do
    assert_not @rejected_nomination.update accepted: nil
  end
end
