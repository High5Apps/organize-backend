class Simulation::Company::Employee
  attr_reader :id, :probability_of_joining
  attr_accessor :team, :linked_employee_set, :closely_linked_employee_set

  def initialize(id)
    @id = id
    @linked_employee_set = Set[]
    @closely_linked_employee_set = Set[]
    @probability_of_joining = rand
  end

  def to_s
    "<Employee #{@id}: probability_of_joining #{@probability_of_joining.round 3}>"
  end
end
