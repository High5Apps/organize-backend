class Simulation::Company::Employee
  attr_reader :id, :index, :probability_of_joining
  attr_accessor :team, :linked_employee_set, :closely_linked_employee_set,
    :asked_closely_linked_employee_set

  def initialize(index, id)
    @index = index
    @id = id
    @linked_employee_set = Set[]
    @closely_linked_employee_set = Set[]
    @asked_closely_linked_employee_set = Set[]
    @probability_of_joining = rand
  end

  def unasked_closely_linked_employee_set
    @closely_linked_employee_set - @asked_closely_linked_employee_set
  end

  # Without this, a stack overflow can occur when any other error tried to print
  # out the sets, which may link to other sets, which link back to this employee
  def inspect
    "<Employee @id=#{@id}, @probability_of_joining=#{@probability_of_joining.round 3}>"
  end

  def to_s
    inspect
  end
end
