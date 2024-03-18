ANNOUNCE_FRACTION = 0.8

org = User.find($simulation.founder_id).org
election_candidate_count = org.ballots.election.joins(:candidates).count

expected_post_count = (ANNOUNCE_FRACTION * election_candidate_count).round
print "\tCreating about #{expected_post_count} candidacy announcements... "
start_time = Time.now

elections = org.ballots.election.includes(candidates: [:user])
elections.each do |election|
  office_title = election.office.titleize

  election.candidates.each do |candidate|
    next unless rand < ANNOUNCE_FRACTION

    pseudonym = candidate.user.pseudonym
    title = "#{pseudonym} is running for #{office_title}"

    created_at = candidate.created_at + 1.minute
    travel_to created_at do
      candidate.create_post! category: :general,
        encrypted_title: $simulation.encrypt(title),
        encrypted_body: $simulation.encrypt(hipster_ipsum_post_body),
        org:,
        user: candidate.user
    end
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
