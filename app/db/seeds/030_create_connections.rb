connection_data = $simulation.to_seed_data[:connections]

print "\tCreating #{connection_data.count} connections... "
start_time = Time.now

connection_data.each do |sharer_id, scanner_id|
  Connection.create sharer_id: $user_id_map[sharer_id],
    scanner_id: $user_id_map[scanner_id]
end

puts "Completed in #{(Time.now - start_time).round 3} s"
