require "test_helper"

class TermTest < ActiveSupport::TestCase
  setup do
    @founder_term = terms(:one)
    @non_founder_term = terms(:three)
  end

  test 'preconditions' do
    assert @founder_term.founder?
    assert_not @non_founder_term.founder?
  end

  test 'should be valid' do
    assert @founder_term.valid?
    assert @non_founder_term.valid?
  end

  test 'accepted should be present' do
    @non_founder_term.accepted = nil
    assert @non_founder_term.invalid?
  end

  test 'accepted can be false' do
    @non_founder_term.accepted = false
    assert @non_founder_term.valid?
  end

  test 'ballot should be absent for founders' do
    @founder_term.ballot = @non_founder_term.ballot
    assert @founder_term.invalid?
  end

  test 'ballot should be present for non-founders' do
    @non_founder_term.ballot = nil
    assert @non_founder_term.invalid?
  end

  test 'ends_at should be present' do
    @founder_term.ends_at = nil
    assert @founder_term.invalid?
  end

  test 'ends_at should be after starts_at' do
    @founder_term.ends_at = @founder_term.starts_at
    assert @founder_term.invalid?

    @founder_term.ends_at = @founder_term.starts_at + 1.second
    assert @founder_term.valid?
  end

  test 'office should be present' do
    @non_founder_term.office = nil
    assert @non_founder_term.invalid?
  end

  test 'office should be included in offices' do
    @non_founder_term.office = :bad_office
    assert @non_founder_term.invalid?
  end

  test 'user should be present' do
    @founder_term.user = nil
    assert_not @founder_term.valid?
  end

  test 'starts_at should be present' do
    @founder_term.starts_at = nil
    assert @founder_term.invalid?
  end

  test 'starts_at should be after created_at for non-founders' do
    @non_founder_term.starts_at = @non_founder_term.created_at
    assert @non_founder_term.invalid?

    @non_founder_term.starts_at = @non_founder_term.created_at + 1.second
    assert @non_founder_term.valid?
  end

  test "user should be org's first member for founder terms" do
    user = users :three
    assert_not_equal user, @founder_term.user

    new_founder_term = @founder_term.dup
    @founder_term.destroy!
    new_founder_term.user = user
    assert new_founder_term.invalid?
  end

  test 'user should have won election for non-founder terms' do
    assert @non_founder_term.valid?
    @non_founder_term.ballot.votes.destroy_all
    assert @non_founder_term.invalid?
  end

  test 'active_at should not include terms where starts_at is in the future' do
    now = Time.now
    starts_ats = [now - 1.second, now, now + 1.second]
    ends_ats = [now + 3.seconds] * starts_ats.count
    t1, t2, t3 = create_terms_with(ends_ats:, starts_ats:)
    query = Term.active_at(now)
    assert query.exists?(id: t1)
    assert query.exists?(id: t2)
    assert_not query.exists?(id: t3)
  end

  test 'active_at should include terms where ends_at is in the future' do
    ends_ats = [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now]
    starts_ats = [1.second.ago] * ends_ats.count
    t1, t2, t3 = create_terms_with(ends_ats:, starts_ats:)
    query = Term.active_at(t2.ends_at)
    assert_not query.exists?(id: t1)
    assert_not query.exists?(id: t2)
    assert query.exists?(id: t3)
  end

  test 'active_at should not include terms that were declined' do
    ends_ats = [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now]
    starts_ats = [1.second.ago] * ends_ats.count
    t1, t2, t3 = create_terms_with(ends_ats:, starts_ats:)

    [true, false].each do |accepted|
      [t1, t2, t3].each { |t| t.update!(accepted:) }
      query = Term.active_at(starts_ats.first)
      [t1, t2, t3].each do |t|
        assert query.exists?(id: t) if accepted
        assert_not query.exists?(id: t) unless accepted
      end
    end
  end

  private

  def create_terms_with(ends_ats:, starts_ats:)
    ends_ats.map.with_index do |ends_at, i|
      starts_at = starts_ats[i]
      term = @non_founder_term.dup

      travel_to starts_at - 1.second do
        term.update!(ends_at:, starts_at:)
      end

      term
    end
  end
end
