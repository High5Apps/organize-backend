org = User.find($simulation.founder_id).org
elections_with_results = org.ballots.election.inactive_at $simulation.ended_at

print "\tCreating about #{elections_with_results.count} terms... "
start_time = Time.now

elections_with_results.each do |election|
  election.winners.each do |winner|
    candidate = Candidate.find winner[:candidate_id]
    sentiment = rand
    next unless sentiment > 0.05 # Neither accepted nor declined: 5%
    accepted = sentiment > 0.1 # Accepted: 90%, declined: 5%
    ballot = candidate.ballot
    travel_to ballot.term_starts_at - 1.second do
      ballot.terms.create!({
        accepted: accepted,
        ends_at: ballot.term_ends_at,
        office: ballot.office,
        starts_at: ballot.term_starts_at,
        user: candidate.user,
      })
    end
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
