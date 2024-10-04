require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  COMPANY_SIZE = 47
  RANDOM_SEED = 12345

  setup do
    @company = Simulation::Company.new(COMPANY_SIZE, random_seed: RANDOM_SEED)
  end

  test 'teams should not be larger than MAX_TEAM_SIZE' do
    @company.teams.each do |team|
      assert_operator team.employees.count, :<=,
        Simulation::Company::MAX_TEAM_SIZE
    end
  end

  test 'should include COMPANY_SIZE employees' do
    assert_equal COMPANY_SIZE, @company.employees.count
  end

  test 'each employee should have a team' do
    @company.employees.each do |employee|
      assert_not_nil employee.team
    end
  end

  test "each employee's team should include the employee" do
    @company.employees.each do |employee|
      assert_includes employee.team.employees, employee
    end
  end

  test 'employees should not be linked to themselves' do
    @company.employees.each do |employee|
      assert_not employee.linked_employee_set.include? employee
    end
  end

  test 'employees should be linked to all team members except self' do
    @company.employees.each do |employee|
      employee.team.employees.each do |team_member|
        is_self = (employee == team_member)
        assert_equal !is_self,
          employee.linked_employee_set.include?(team_member)
      end
    end
  end

  test 'partner_teams count should at most MAX_PARTNER_TEAMS_COUNT' do
    max = Simulation::Company::MAX_PARTNER_TEAMS_COUNT
    @company.teams.each do |team|
      assert_operator team.partner_teams.count, :<=, max
    end
  end

  test 'even id teams should only be paired with odd id teams' do
    @company.teams.each do |team|
      team.partner_teams.each do |partner_team|
        assert_not_equal team.id.even?, partner_team.id.even?
      end
    end
  end

  test 'all linked employees should linked in both directions' do
    @company.employees.each do |employee|
      employee.linked_employee_set.each do |linked_employee|
        assert_includes linked_employee.linked_employee_set, employee
      end
    end
  end

  test 'closely_linked_employee_set should be a subset of linked_employee_set' do
    @company.employees.each do |employee|
      assert_operator employee.closely_linked_employee_set, :subset?,
        employee.linked_employee_set
    end
  end
end
