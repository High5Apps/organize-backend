user_ids = $simulation.to_seed_data[:user_ids]

print "\tCreating #{user_ids.count} users... "
start_time = Time.now

Timecop.freeze($simulation.started_at) do
  user_ids.each do |user_id|
    key_pair = OpenSSL::PKey::EC.generate "prime256v1"
    User.create! id: user_id, public_key_bytes: key_pair.public_to_der
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
