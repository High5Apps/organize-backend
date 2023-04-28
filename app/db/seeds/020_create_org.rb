print "\tCreating Org... "
start_time = Time.now

creator = User.first

org = creator.create_org! name: 'Org',
  potential_member_definition: 'Definition',
  potential_member_estimate: $simulation.to_seed_data[:size]

creator.save!

puts "Completed in #{(Time.now - start_time).round 3} s"
