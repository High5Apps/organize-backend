founder = User.find($simulation.founder_id)
org = founder.org

flaggable_type_counts = org.flags.group(:flaggable_type).count
moderation_event_count = 2 * flaggable_type_counts.keys.count

print "\tCreating about #{moderation_event_count} ModerationEvents... "
start_time = Time.now

flaggable_type_counts.keys.each do |flaggable_type|
  ordered_by_flag_count = org.flags
    .where(flaggable_type: flaggable_type)
    .group(:flaggable_id)
    .select(:flaggable_id, 'COUNT(*) AS flag_count')
    .order(:flag_count, :flaggable_id)

  # Find a ballot with the min flag count and allow it
  flaggable_id_to_allow = ordered_by_flag_count.first.flaggable_id
  founder.created_moderation_events.create!({
    action: 'allow',
    moderatable_id: flaggable_id_to_allow,
    moderatable_type: flaggable_type,
  })

  # Find a random ballot with the max flag count to block
  flaggable_id_to_block = ordered_by_flag_count.last.flaggable_id

  # If the flaggable to block is the same the allowed one, must undo_allow first
  if flaggable_id_to_block == flaggable_id_to_allow
    founder.created_moderation_events.create!({
      action: 'undo_allow',
      moderatable_id: flaggable_id_to_block,
      moderatable_type: flaggable_type,
    })
  end

  # Block the flaggable
  founder.created_moderation_events.create!({
    action: 'block',
    moderatable_id: flaggable_id_to_block,
    moderatable_type: flaggable_type,
  })
end

puts "Completed in #{(Time.now - start_time).round 3} s"
