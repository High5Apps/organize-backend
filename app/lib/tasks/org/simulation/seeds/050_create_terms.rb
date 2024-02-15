offices = Office::TYPE_SYMBOLS
founder = User.find($simulation.founder_id)
org = founder.org
user_ids = org.users.ids
user_count = user_ids.count
users_per_steward = rand 15..25
steward_count = (user_count / users_per_steward)

# -1 because offices already includes a steward
term_count = offices.count - 1 + steward_count

print "\tCreating up to #{term_count} terms... "
start_time = Time.now

catch :stop_creating_terms do
  Timecop.freeze($simulation.ended_at) do
    graph = org.graph
    term_map = {}

    offices.each do |office|
      user_id = case office
      when :founder
        # Already automatically created during first Org creation
      when :president
        # If there's no president, don't create any other terms.
        # This relies on offices being in rank order
        throw :stop_creating_terms unless rand < 0.9

        # Most popular node. i.e. the node with the most connections
        president_id_data = graph[:users].max_by {|id, u| u[:connection_count]}
        president_id = president_id_data.first
        president_id
      when :vice_president
        next unless rand < 0.5

        # President's most popular connection
        president = term_map[:president].user
        connection_ids = president.scanners.ids + president.sharers.ids
        vp_id = connection_ids.max_by {|id| graph[:users][id][:connection_count]}
        vp_id
      when :secretary
        next unless rand < 0.5
        user_ids.sample # Random user in Org
      when :treasurer
        next unless rand < 0.75
        user_ids.sample # Random user in Org
      when :steward
        # Handled below after all other officers are created
      when :trustee
        # No need for a trustee without a treasurer
        treasurer = term_map[:treasurer].user
        next unless treasurer
        next unless rand < 0.25

        # Random user that isn't connected to the treasurer
        connection_ids = treasurer.scanners.ids + treasurer.sharers.ids
        user_ids_not_connected_to_treasurer = user_ids - connection_ids
        user_ids_not_connected_to_treasurer.sample
      else
        throw "Unhandled office: #{office}"
      end

      next unless user_id

      term = User.find(user_id).terms.create!(office:)

      term_map[office] = term
    end

    # Handle Stewards
    # Random users that aren't already an elected officer (could be the Founder)
    officer_ids = term_map.values.map(&:user_id)
    non_officer_ids = user_ids - officer_ids
    steward_ids = non_officer_ids.sample(steward_count)
    steward_ids.each do |steward_id|
      User.find(steward_id).terms.create!(office: :steward)
    end
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
