class Simulation::Company::Team
  attr_accessor :employees, :partner_teams
  attr_reader :id

  def initialize(id)
    @id = id
    @employees = []
    @partner_teams = []
  end
end
