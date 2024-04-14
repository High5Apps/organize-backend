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

  test 'can? should use the specific default when no permission is found' do
    assert_empty @pending_president.org.permissions.create_elections

    specific_default = Permission::Defaults[:create_elections]
    assert_not_equal Permission::Data.new(specific_default).attributes,
      Permission::Data.new(Permission::Defaults::DEFAULT_DEFAULT).attributes

    term = @pending_president.terms.first
    travel_to term.starts_at do
      assert_not_empty @pending_president.terms.active_at(Time.now).president

      Office::TYPE_STRINGS.each do |office|
        term.office = office
        term.save! validate: false

        expect_can = specific_default[:offices].include? office
        assert_equal expect_can,
          Permission.can?(@pending_president.reload, :create_elections)
      end
    end
  end

  test 'can? should use the default-default when no permission is found and no default exists' do
    @pending_president.org.permissions.destroy_all
    assert_empty @pending_president.org.permissions

    term = @pending_president.terms.first
    travel_to term.starts_at do
      assert_not_empty @pending_president.terms.active_at(Time.now).president

      Office::TYPE_STRINGS.each do |office|
        term.office = office
        term.save! validate: false

        expect_can = Permission::Defaults::DEFAULT_DEFAULT[:offices]
          .include? office
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

  test 'who_can should return nil when org is nil' do
    nil_org = nil
    assert_nil Permission.who_can :edit_permissions, nil_org
  end

  test 'who_can should return nil for unknown scopes' do
    assert_nil Permission.who_can :bad_scope, orgs(:one)
  end

  test 'who_can should return the permission data when available' do
    assert_equal @permission.data.attributes,
      Permission.who_can(@permission.scope, @permission.org).attributes
  end

  test 'who_can should return the specific default when permission unavailable' do
    assert_empty @pending_president.org.permissions.create_elections
    specific_default = Permission::Defaults::DEFAULTS[:create_elections]
    assert_not_equal Permission::Data.new(specific_default).attributes,
      Permission::Data.new(Permission::Defaults::DEFAULT_DEFAULT).attributes
    assert_equal Permission::Data.new(specific_default).attributes,
      Permission.who_can(:create_elections, @pending_president.org).attributes
  end

  test 'who_can should return the default-default when permission unavailable and no specific default' do
    assert_empty @founder.org.permissions
    assert_nil Permission::Defaults::DEFAULTS[:edit_permissions]
    default_default = Permission::Defaults::DEFAULT_DEFAULT
    assert_equal Permission::Data::new(default_default).attributes,
      Permission.who_can(:edit_permissions, @founder.org).attributes
  end
end
