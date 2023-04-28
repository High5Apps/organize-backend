class Simulation
  def initialize
    start = Time.now

    size = rand(20..100)
    @company = Company.new(size)

    finish = Time.now
    puts "Initialized company in #{(finish - start).round 3} s"
  end

  def run
    puts @company.most_passionate_employee
    puts @company.link_stats
    puts @company.close_link_stats
  end
end
