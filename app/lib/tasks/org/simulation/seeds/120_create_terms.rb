org = User.find($simulation.founder_id).org
elections_with_results = org.ballots.election.inactive_at $simulation.ended_at

print "\tCreating about #{elections_with_results.count} terms... "
start_time = Time.now

elections_with_results.each do |election|
  election.winners.each do |winner|
    candidate = Candidate.find winner[:candidate_id]
    ballot = candidate.ballot
    ballot.terms.create!({
      ends_at: ballot.term_ends_at,
      office: ballot.office,
      user: candidate.user,
    })
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"