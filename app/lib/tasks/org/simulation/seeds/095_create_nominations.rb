org = User.find($simulation.founder_id).org
users = org.users
elections = org.ballots.election

print "\tCreating about #{5 * elections.count} nominations... "
start_time = Time.now

elections.each do |election|
  nominations_end = election.nominations_end_at
  joined_users = users.joined_before(nominations_end)
  max_nomination_count = rand 1..10
  nominators_and_nominees = joined_users.ids.sample 2 * max_nomination_count
  nomination_count = nominators_and_nominees.count / 2

  nomination_count.times do
    nominator_id, nominee_id = nominators_and_nominees.shift 2
    nomination_created_at = rand (election.created_at)...nominations_end
    nomination = nil
    travel_to nomination_created_at do
      nomination = election.nominations.create!(nominator_id:, nominee_id:)
    end

    if rand < 0.6
      # Accept the nomination 60% of the time
      accepted = true
    elsif rand < 0.5
      # Decline the nomination 20% of the time
      accepted = false
    else
      # Ignore 20% of the time
      next
    end

    accepted_or_declined_at = rand nomination_created_at...nominations_end
    travel_to accepted_or_declined_at do
      nomination.update!(accepted:)
    end
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
