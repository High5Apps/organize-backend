puts "Creating seeds..."
start_time = Time.now

$simulation = Simulation.new
$simulation.run
$user_id_map = {}

Dir[
  File.join(Rails.root, 'lib', 'tasks', 'org', 'simulation', 'seeds', '*.rb')
].sort.each { |seed| load seed }

puts "Created seeds. Completed in #{(Time.now - start_time).round 3} s"
