require "test_helper"

class TermTest < ActiveSupport::TestCase
  setup do
    @term = terms(:one)
    @non_founder_term = terms(:three)
  end

  test 'should be valid' do
    assert @term.valid?
  end

  test 'ballot should be absent for founders' do
    assert @term.founder?
    @term.ballot = @non_founder_term.ballot
    assert @term.invalid?
  end

  test 'ballot should be present for non-founders' do
    assert_not @non_founder_term.founder?
    @non_founder_term.ballot = nil
    assert @non_founder_term.invalid?
  end

  test 'ends_at should be present' do
    @term.ends_at = nil
    assert @term.invalid?
  end

  test 'ends_at should be after created_at' do
    @term.ends_at = @term.created_at
    assert @term.invalid?

    @term.ends_at = @term.created_at + 1.second
    assert @term.valid?
  end

  test 'office should be present' do
    @term.office = nil
    assert @term.invalid?
  end

  test 'user should be present' do
    @term.user = nil
    assert_not @term.valid?
  end

  test "user should be org's first member for founder terms" do
    user = users :three
    founder_term = @term
    assert @term.founder?
    assert_not_equal user, @term.user

    term = founder_term.dup
    founder_term.destroy!
    term.user = user
    assert term.invalid?
  end

  test 'user should have won election for non-founder terms' do
    assert @non_founder_term.valid?
    @non_founder_term.ballot.votes.destroy_all
    assert @non_founder_term.invalid?
  end

  test 'active_at should include terms where ends_at is in the future' do
    t1, t2, t3 = create_terms_with_ends_at(
      [1.second.from_now, 2.seconds.from_now, 3.seconds.from_now])
    query = Term.active_at(t2.ends_at)
    assert_not query.exists?(id: t1)
    assert_not query.exists?(id: t2)
    assert query.exists?(id: t3)
  end

  private

  def create_terms_with_ends_at(ends_ats)
    ends_ats.map do |ends_at|
      term = @term.dup
      term.update!(ends_at:)
      term
    end
  end
end
