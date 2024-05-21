require "test_helper"

class FlagTest < ActiveSupport::TestCase
  setup do
    @flag = flags :one
    @flaggables = [ballots(:three), comments(:two), posts(:three)]
  end

  test 'should be valid' do
    flags.each { |flag| assert flag.valid? }
  end

  test 'flaggable should be present' do
    @flag.flaggable = nil
    assert @flag.invalid?
  end

  test 'flaggable_type should be in ALLOWED_TYPES' do
    @flag.flaggable = upvotes :one
    assert @flag.invalid?
  end

  test 'user should be present' do
    @flag.user = nil
    assert @flag.invalid?
  end

  test 'should not allow users to double flag the same flaggable' do
    flags.each do |flag|
      assert_no_difference 'Flag.count' do
        assert_raises do
          duplicate = flag.dup
          assert_not duplicate.save
        end
      end
    end
  end

  test 'should not allow elections to be flagged' do
    election = ballots :election_one
    flag = @flag.dup
    flag.flaggable = election
    assert flag.invalid?
  end

  test 'should not allow candidacy announcements to be flagged' do
    candidacy_announcement = posts :candidacy_announcement
    flag = @flag.dup
    flag.flaggable = candidacy_announcement
    assert flag.invalid?
  end

  test 'flaggable should belong to user Org' do
    flaggable_in_another_org = ballots :two
    assert_not_equal flaggable_in_another_org.org, @flag.user.org
    @flag.flaggable = flaggable_in_another_org
    assert @flag.invalid?
  end

  test 'creator should belong to an Org' do
    user_without_org = users :two
    assert_nil user_without_org.org
    @flag.user = user_without_org
    assert @flag.invalid?
  end

  test 'created_at_or_before should include flags where created_at is not after time' do
    [
      [@flag.created_at - 1.second, false],
      [@flag.created_at, true],
      [@flag.created_at + 1.second, true],
    ].each do |query_time, expect_exists|
      query = Flag.created_at_or_before(query_time)
      assert_equal expect_exists, query.exists?(id: @flag.id)
    end
  end
end
