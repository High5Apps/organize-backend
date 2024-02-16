require "test_helper"

class TermTest < ActiveSupport::TestCase
  setup do
    @term = terms(:one)
  end

  test 'should be valid' do
    assert @term.valid?
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
