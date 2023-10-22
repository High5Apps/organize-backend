office_names = [
  # Founder is automatically created during org creation
  'President',
  'Vice President',
  'Secretary',
  'Treasurer',
  'Steward',
  'Trustee',
]

# Only run this if offices haven't already been created
return if Office.count >= office_names.count

print "\tCreating #{office_names.count} offices... "
start_time = Time.now

Timecop.freeze($simulation.started_at) do
  office_names.each do |office_name|
    Office.create! name: office_name
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
