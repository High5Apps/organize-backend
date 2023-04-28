user_ids = $simulation.to_seed_data[:user_ids]

print "\tCreating #{user_ids.count} users... "
start_time = Time.now

users = user_ids.map do |user_id|
  key_pair = OpenSSL::PKey::EC.generate "prime256v1"
  User.create! public_key_bytes: key_pair.public_to_der
end

user_guids = users.map(&:id)
$user_id_map = user_ids.zip(user_guids).to_h

puts "Completed in #{(Time.now - start_time).round 3} s"
