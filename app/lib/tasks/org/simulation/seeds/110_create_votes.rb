VOTER_TURNOUT_DISTRIBUTION = Rubystats::NormalDistribution.new(0.7, 0.1)

org = User.find($simulation.founder_id).org
users = org.users
ballots = org.ballots

print "\tCreating votes on #{ballots.count} ballots... "
start_time = Time.now

values = []

ballots.all.each do |ballot|
  candidate_ids = ballot.candidates.ids
  next if candidate_ids.blank?

  max_candidate_ids_per_vote = ballot.max_candidate_ids_per_vote
  selection_map = {}

  potential_voter_ids = users.where(joined_at: ...ballot.created_at).ids
  voter_turnout_fraction = VOTER_TURNOUT_DISTRIBUTION.rng.clamp(0, 1)
  voter_turnout_count = (potential_voter_ids.count * voter_turnout_fraction)
    .floor
  voter_ids = potential_voter_ids.sample(voter_turnout_count)
  current_voter_ids = voter_ids

  max_candidate_ids_per_vote.times do
    # Randomly place (n-1) dividers to split up the spectrum into n sections
    # -------|----|---|-
    position_distribution = Rubystats::UniformDistribution.new 0,
      current_voter_ids.count
    spectrum_dividers = (1...candidate_ids.count)
      .map { position_distribution.rng.floor }
      .sort
    candidate_vote_counts = [0, *spectrum_dividers, current_voter_ids.count]
      .each_cons(2)
      .map { |a, b| b - a }

    current_candidate_index = 0
    current_candidate_vote_count = 0
    current_voter_ids.each_with_index do |voter_id, i|
      unless current_candidate_vote_count < candidate_vote_counts[current_candidate_index]
        current_candidate_vote_count = 0
        current_candidate_index += 1
      end

      unless selection_map.key? voter_id
        selection_map[voter_id] = []
      end

      selection_map[voter_id].push candidate_ids[current_candidate_index]
      current_candidate_vote_count += 1
    end

    # When multiple votes are allowed, 90% of the previous voters create another
    # vote
    next_round_voter_count = (0.9 * current_voter_ids.count).floor
    current_voter_ids = current_voter_ids.sample(next_round_voter_count)
  end

  selection_map.each do |voter_id, selected_candidate_ids|
    values.push({
      ballot_id: ballot.id,
      candidate_ids: selected_candidate_ids.uniq,
      created_at: ballot.created_at + 1.second,
      updated_at: ballot.created_at + 1.second,
      user_id: voter_id,
    })
  end
end

Vote.insert_all values unless values.empty?

puts "Completed in #{(Time.now - start_time).round 3} s"
