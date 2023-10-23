user_ids = $simulation.to_seed_data[:user_ids]

print "\tCreating #{user_ids.count} users... "
start_time = Time.now

Timecop.freeze($simulation.started_at) do
  user_ids.each do |user_id|
    if user_id == $simulation.founder_id
      # Update founder timestamps to align with simulation timestamps.
      # Otherwise the founder would have a shorter tenure than other members.
      founder = User.find(user_id)
      founder.update! created_at: $simulation.started_at,
        joined_at: $simulation.started_at

      # Don't attempt to recreate the pre-existing founder
      next
    end

    key_pair = OpenSSL::PKey::EC.generate "prime256v1"
    User.create! id: user_id, public_key_bytes: key_pair.public_to_der
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
