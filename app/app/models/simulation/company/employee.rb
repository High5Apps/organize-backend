class Simulation::Company::Employee
  attr_reader :id
  attr_accessor :team
  attr_accessor :linked_employee_set

  def initialize(id)
    @id = id
    @linked_employee_set = Set[]
  end
end
