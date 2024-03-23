should_create_elections = rand < 0.9
offices = should_create_elections ? Office::TYPE_SYMBOLS : []

print "\tCreating about #{should_create_elections ? 4 : 0} elections... "
start_time = Time.now

founder = User.find($simulation.founder_id)
org = founder.org
user_count = org.users.count
users_per_steward = rand 15..25
steward_count = (user_count / users_per_steward)

# Must be in progress order. :term appears twice to increase its likelihood
states = [
  :none, :nominations, :voting, :term_acceptance, :term, :term,
]
state_map = {}
offices.each do |office|
  # This relies on Office::TYPE_SYMBOLS being in rank order
  state = case office
  when :founder
    # Already automatically created during first Org creation
    :none
  when :president, :treasurer
    states.sample
  when :vice_president, :secretary
    # Don't allow VP or secretary state to be ahead of president state
    president_state_index = states.rindex(state_map[:president])
    states[..president_state_index].sample
  when :steward
    (steward_count == 0) ? :none : states.sample
  when :trustee
    # Don't allow trustee state to be ahead of treasurer state
    treasurer_state_index = states.rindex(state_map[:treasurer])
    states[..treasurer_state_index].sample
  else
    raise "Unhandled office: #{office}"
  end

  state_map[office] = state
  next if state == :none

  office_title = office.to_s.titleize
  encrypted_question = \
    $simulation.encrypt("Who should we elect #{office_title}?")

  max_candidate_ids_per_vote = (office == :steward) ? steward_count : 1

  voting_ends_at = $simulation.ended_at + {
    term: -2.days,
    term_acceptance: -1.day,
    voting: 1.day,
    nominations: 2.days,
  }[state]
  term_starts_at = voting_ends_at + 2.days
  term_ends_at = term_starts_at + 1.year
  nominations_end_at = voting_ends_at - 1.day
  created_at = nominations_end_at - 2.days

  travel_to created_at do
    founder.ballots.create!({
      category: 'election',
      encrypted_question:,
      max_candidate_ids_per_vote:,
      nominations_end_at:,
      office:,
      term_ends_at:,
      term_starts_at:,
      voting_ends_at:,
    })
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
