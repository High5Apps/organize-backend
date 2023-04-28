class Simulation::Company
  MAX_PARTNER_TEAMS_COUNT = 3

  # Note that there's no absolute MIN_TEAM_SIZE because the final team size is
  # clamped to the number of remaining unplaced employees
  NORMAL_MIN_TEAM_SIZE = 4
  MAX_TEAM_SIZE = 10
  
  attr_reader :size

  def initialize(size, random_seed: nil)
    @size = size

    if random_seed
      srand(random_seed)
    end

    employees
    teams
    assign_partner_teams
    create_links
  end

  def employees
    return @employees if @employees
    @employees = (0...@size).map { |i| Employee.new i }
  end

  def teams
    return @teams if @teams

    @teams = []
    placed_employee_count = 0
    while @size - placed_employee_count > 0
      unplaced_employee_count = @size - placed_employee_count
      random_team_size = rand NORMAL_MIN_TEAM_SIZE..MAX_TEAM_SIZE
      clamped_team_size = [random_team_size, unplaced_employee_count].min
      team = Team.new(@teams.count)
      team_members = employees[placed_employee_count, clamped_team_size]
      team.employees += team_members
      @teams.push(team)

      team_members.each do |team_member|
        team_member.team = team
      end

      placed_employee_count += clamped_team_size
    end

    @teams
  end

  def link_stats
    link_counts = employees.map { |e| e.linked_employee_set.count }
    array_stats(link_counts)
  end

  def close_link_stats
    close_link_counts = employees.map do |e|
      e.closely_linked_employee_set.count
    end
    array_stats(close_link_counts)
  end

  def most_passionate_employee
    employees.max do |e1, e2|
      e1.probability_of_joining <=> e2.probability_of_joining
    end
  end

  # https://graphonline.ru/en/create_graph_by_edge_list
  def to_edge_list
    edge_set = Set[]
    employees.each do |employee|
      employee.linked_employee_set.each do |linked_employee|
        smaller_id, larger_id = [employee.id, linked_employee.id].minmax
        edge_set.add "#{smaller_id}-#{larger_id}"
      end
    end

    edge_set.to_a.join "\n"
  end

  private

  def assign_partner_teams
    odd_teams = teams.select { |t| t.id.odd? }

    even_teams.each do |even_team|
      partner_team_count = rand(0..MAX_PARTNER_TEAMS_COUNT)
      potential_partner_teams = odd_teams.sample(partner_team_count)
      partner_teams = potential_partner_teams.filter do |t|
        t.partner_teams.count < MAX_PARTNER_TEAMS_COUNT
      end
      even_team.partner_teams = partner_teams
      partner_teams.each do |partner_team|
        partner_team.partner_teams.push(even_team)
      end
    end
  end

  def even_teams
    return @even_teams if @even_teams
    @even_teams = teams.select { |t| t.id.even? }
  end

  def create_links
    create_links_between_team_members_excluding_self_links
    create_links_between_partner_teams
    create_random_links
  end

  # Each employee is linked to all members of their team. Close links are formed
  # with a probability based on a normal distribution.
  def create_links_between_team_members_excluding_self_links
    closeness_distribution = Rubystats::NormalDistribution.new(0.5, 0.2)
    teams.each do |team|
      closeness = closeness_distribution.rng
      team.employees.each do |team_member_i|
        team.employees.each do |team_member_j|
          next if team_member_i.id == team_member_j.id
          team_member_i.linked_employee_set.add team_member_j

          next unless team_member_i.id < team_member_j.id
          next unless closeness > rand
          team_member_i.closely_linked_employee_set.add team_member_j
          team_member_j.closely_linked_employee_set.add team_member_i
        end
      end
    end
  end

  # Each partner team pair is assigned a closeness probability. Then each
  # employee of the partner team pair is linked based on that closeness
  # probability. Then there's a 50% chance of that being a close link.
  def create_links_between_partner_teams
    even_teams.each do |even_team|
      even_team.partner_teams.each do |partner_team|
        closeness = rand 30..50
        even_team.employees.each do |even_team_member|
          partner_team.employees.each do |partner_team_member|
            next unless closeness > rand(0..100)
            even_team_member.linked_employee_set.add partner_team_member
            partner_team_member.linked_employee_set.add even_team_member

            next unless rand < 0.5
            even_team_member.closely_linked_employee_set.add partner_team_member
            partner_team_member.closely_linked_employee_set.add even_team_member
          end
        end
      end
    end
  end

  # Each employee is linked to up to 10 random people in the company.
  # Then there's a 50% chance of those links being a close link.
  def create_random_links
    even_employees = employees.select { |e| e.id.even? }
    odd_employees = employees.select { |e| e.id.odd? }

    even_employees.each do |even_employee|
      random_link_count = rand 0..10
      random_odd_employees = odd_employees.sample random_link_count
      random_odd_employees.each do |random_odd_employee|
        even_employee.linked_employee_set.add random_odd_employee
        random_odd_employee.linked_employee_set.add even_employee

        next unless rand < 0.5
        even_employee.closely_linked_employee_set.add random_odd_employee
        random_odd_employee.closely_linked_employee_set.add even_employee
      end
    end
  end

  def array_stats(array)
    sorted_array = array.sort
    size = sorted_array.count
    sum = sorted_array.sum
    minimum, maximum = sorted_array.minmax
    average = sum.to_f / size

     # Not true median- doesn't average middle two
    median = sorted_array[size / 2]
    %{
Link Stats:
  Company size: #{@size}
  Link count: #{sum}
  Min: #{minimum}
  Max: #{maximum}
  Average: #{average.round 2}
  Median: #{median}
    }
  end
end
