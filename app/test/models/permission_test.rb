require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  setup do
    @permission = permissions :one_edit_permissions
    @founder = users :five
    @pending_president = users :four
    @non_officer = users :three
  end

  test 'preconditions' do
    assert_equal ['founder'], @founder.terms.pluck(:office)

    assert_not_empty @pending_president.terms.president
    assert_empty @pending_president.terms.active_at(Time.now).president

    assert_empty @non_officer.terms
  end

  test 'should be valid' do
    assert @permission.valid?
  end

  test 'data should be present' do
    @permission.data = nil
    assert @permission.invalid?
  end

  test 'data should be valid' do
    @permission.data = { offices: ['bad_office'] }
    assert @permission.invalid?
  end

  test 'org should be present' do
    @permission.org = nil
    assert @permission.invalid?
  end

  test 'scope should be present' do
    @permission.scope = nil
    assert @permission.invalid?
  end

  test 'scope should be included in scopes' do
    @permission.scope = :bad_scope
    assert @permission.invalid?
  end

  test 'should not allow multiple with the same scope in an Org' do
    assert_no_difference 'Permission.count' do
      assert_raises do
        @permission.dup.save
      end
    end
  end

  test 'should not update if it would not allow anyone to do it' do
    unfilled_office = 'secretary'
    assert_not_includes @permission.org.terms.active_at(Time.now).map(&:office),
      unfilled_office
    @permission.data = { offices: [unfilled_office] }
    assert @permission.invalid?
  end

  test 'should not prevent president from editing permissions' do
    assert @permission.edit_permissions?
    @permission.data = { offices: ['founder'] }
    assert @permission.invalid?
  end

  test 'can? should return false when user is not in an Org' do
    user_without_org = users :two
    assert_nil user_without_org.org
    Permission::SCOPE_SYMBOLS.each do |scope|
      assert_not Permission.can? user_without_org, scope
    end
  end

  test 'can? should return false for non-officers' do
    Permission::SCOPE_SYMBOLS.each do |scope|
      assert_not Permission.can? @non_officer, scope
    end
  end

  test 'can? should return false for unexpected scopes' do
    assert_not Permission.can? @founder, :bad_scope
  end

  test 'can? should use the default param when no permission is found' do
    assert_empty @founder.org.permissions
    Office::TYPE_STRINGS.each do |office|
      assert_equal (office == 'founder'),
        Permission.can?(@founder, :edit_permissions, offices: [office])
    end
  end

  test 'can? should use the default-default when no permission is found and no default param is given' do
    term = @pending_president.terms.first
    travel_to term.starts_at do
      assert_not_empty @pending_president.terms.active_at(Time.now).president

      Office::TYPE_STRINGS.each do |office|
        term.office = office
        term.save! validate: false

        expect_can = Permission::DEFAULT_DEFAULT_DATA[:offices].include? office
        assert_equal expect_can,
          Permission.can?(@pending_president.reload, :edit_permissions)
      end
    end
  end

  test 'can? should only return true for the officers listed in data.offices' do
    term = @pending_president.terms.first
    travel_to term.starts_at do
      assert_not_empty @pending_president.terms.active_at(Time.now).president

      Office::TYPE_STRINGS.each do |office|
        term.office = office
        term.save! validate: false

        expect_can = @permission.data.offices.include? office
        assert_equal expect_can,
          Permission.can?(@pending_president.reload, :edit_permissions)
      end
    end
  end

  test 'can? should return false for pending officers that would be allowed once they become active' do
    [
      [Time.now, false],
      [@pending_president.terms.first.starts_at, true],
    ].each do |time, expect_can|
      travel_to time do
        assert_equal expect_can,
          Permission.can?(@pending_president, :edit_permissions)
      end
    end
  end
end
