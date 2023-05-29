USERS_PER_STEWARD = 20

offices = Office.all
user_count = User.count
steward_count = (user_count / USERS_PER_STEWARD)

# -1 because offices already includes a steward
term_count = offices.count - 1 + steward_count

print "\tCreating #{term_count} terms... "
start_time = Time.now

Timecop.freeze($simulation.ended_at) do
  graph = Org.first.graph
  term_map = {}

  offices.each do |office|
    user_id = case office.name
    when 'Founder'
      # Already automatically created during first Org creation
    when 'President'
      # Most popular node. i.e. the node with the most connections
      president_id_data = graph[:users].max_by {|id, u| u[:connection_count]}
      president_id = president_id_data.first
      president_id
    when 'Vice President'
      # President's most popular connection
      president = term_map['President'].user
      connection_ids = president.scanners.ids + president.sharers.ids
      vp_id = connection_ids.max_by {|id| graph[:users][id][:connection_count]}
      vp_id
    when 'Secretary', 'Treasurer'
      # Random user
      User.ids.sample
    when 'Steward'
      # Handled below after all other officers are created
    when 'Trustee'
      # Random user that isn't connected to the treasurer
      treasurer = term_map['Treasurer'].user
      connection_ids = treasurer.scanners.ids + treasurer.sharers.ids
      user_ids_not_connected_to_treasurer = User.ids - connection_ids
      user_ids_not_connected_to_treasurer.sample
    else
      throw "Unhandled Office name: #{office.name}"
    end

    next unless user_id

    term = User.find(user_id).terms.create!(office: office)

    term_map[office.name] = term
  end

  # Handle Stewards
  # Random users that aren't already an elected officer (could be the Founder)
  officer_ids = term_map.values.map(&:user_id)
  non_officer_ids = User.ids - officer_ids
  steward_ids = non_officer_ids.sample(steward_count)
  steward = Office.find_by_name('Steward')
  steward_ids.each do |steward_id|
    User.find(steward_id).terms.create!(office: steward)
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
