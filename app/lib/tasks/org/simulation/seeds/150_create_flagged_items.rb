FLAGGED_DOWNVOTES_FRACTION = 0.03
FLAGGED_VOTES_FRACTION = 0.01

def create_flagged_items(relation, item_name, flagged_fraction)
  expected_flag_count = (relation.count * flagged_fraction).round
  print "\tCreating roughly #{expected_flag_count} FlaggedItems on #{item_name}... "
  start_time = Time.now

  values = []

  relation.find_each do |item|
    next unless rand < flagged_fraction

    created_at = item.created_at + 3.seconds
    values.push({
      ballot_id: item[:ballot_id], # nil for non-ballots
      comment_id: item[:comment_id], # nil for downvotes on posts
      post_id: item[:post_id], # nil for downvotes on comments
      user_id: item.user_id,
      created_at: created_at,
      updated_at: created_at,
    })
  end

  FlaggedItem.insert_all values unless values.empty?

  puts "Completed in #{(Time.now - start_time).round 3} s"
end

org = User.find($simulation.founder_id).org

downvotes = org.upvotes.where(value: -1)
create_flagged_items downvotes, 'Posts and Comments', FLAGGED_DOWNVOTES_FRACTION

non_election_votes = org.ballots.not_election.joins(:votes)
create_flagged_items non_election_votes, 'Ballots', FLAGGED_VOTES_FRACTION
