desc "Simulate Org formation in a company"
task :simulation => :environment do |task_name|
  simulation = Simulation.new()
  simulation.run
end

# Alias rake sim to rake simulation
task :sim => :simulation
