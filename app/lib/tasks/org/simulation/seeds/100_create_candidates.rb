ballots = User.find($simulation.founder_id).org.ballots

yes_no_ballots = ballots.yes_no
multiple_choice_ballots = ballots.multiple_choice

approximate_candidate_count = \
  2 * yes_no_ballots.count + 6 * multiple_choice_ballots.count

print "\tCreating about #{approximate_candidate_count} candidates... "
start_time = Time.now

yes_no_ballots.all.each do |ballot|
  Timecop.freeze ballot.created_at do
    ballot.candidates.create! encrypted_title: $simulation.encrypt('Yes')
    ballot.candidates.create! encrypted_title: $simulation.encrypt('No')
  end
end

def hipster_ipsum_candidate_title
  title_length = rand 3..Candidate::MAX_TITLE_LENGTH
  Faker::Hipster.paragraph_by_chars(characters: title_length)
    .delete('.') # Remove all periods
end

multiple_choice_ballots.all.each do |ballot|
  Timecop.freeze ballot.created_at do
    candidate_count = rand 2..10
    selection_count = rand 1..candidate_count

    candidate_count.times do
      title = hipster_ipsum_candidate_title
      ballot.candidates.create! encrypted_title: $simulation.encrypt(title)
      ballot.update(max_candidate_ids_per_vote: selection_count)
    end
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
