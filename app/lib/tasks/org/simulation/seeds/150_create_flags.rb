FLAGGED_DOWNVOTES_FRACTION = 0.03
FLAGGED_VOTES_FRACTION = 0.01

def create_flags(relation, flaggable_name, flagged_fraction, org)
  expected_flag_count = (relation.count * flagged_fraction).round
  print "\tCreating roughly #{expected_flag_count} flags on #{flaggable_name.pluralize}... "
  start_time = Time.now

  values = []

  relation.find_each do |flaggable|
    next unless rand < flagged_fraction

    created_at = flaggable.created_at + 3.seconds

    # Pick a random member who had joined by that time to be the flag_creator
    flag_creator = org.users.joined_at_or_before(created_at).sample

    values.push({
      flaggable_id: flaggable[flaggable_name.foreign_key] || flaggable.id,
      flaggable_type: flaggable_name,
      user_id: flag_creator.id,
      created_at: created_at,
      updated_at: created_at,
    })
  end

  Flag.insert_all values unless values.empty?

  puts "Completed in #{(Time.now - start_time).round 3} s"
end

org = User.find($simulation.founder_id).org
downvotes = org.upvotes.where(value: -1)

posts_without_candidacy_announcements = downvotes.joins(:post)
  .where(post: { candidate_id: nil })
create_flags posts_without_candidacy_announcements,
  'Post', FLAGGED_DOWNVOTES_FRACTION, org

comments = downvotes.joins(:comment)
create_flags comments, 'Comment', FLAGGED_DOWNVOTES_FRACTION, org

non_election_votes = org.ballots.not_election.joins(:votes)
create_flags non_election_votes, 'Ballot', FLAGGED_VOTES_FRACTION, org
