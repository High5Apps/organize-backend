ballots = User.find($simulation.founder_id).org.ballots

yes_no_ballots = ballots.yes_no

candidate_count = 2 * yes_no_ballots.count

print "\tCreating #{candidate_count} candidates... "
start_time = Time.now

yes_no_ballots.all.each do |ballot|
  Timecop.freeze ballot.created_at do
    ballot.candidates.create! encrypted_title: $simulation.encrypt('Yes')
    ballot.candidates.create! encrypted_title: $simulation.encrypt('No')
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
