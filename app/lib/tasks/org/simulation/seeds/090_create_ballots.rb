# The Pareto distribution below is unbounded and can sometimes be more than
# 1000. This cap helps to guard against those rare and unrealistic scenarios.
BALLOT_DISTRIBUTION_MAX = 30

BALLOTS_DISTRIBUTION = -> { [(1/rand).round, BALLOT_DISTRIBUTION_MAX].min }

QUESTION_PREFIXES = {
  multiple_choice: 'Which of these should we ',
  yes_no: 'Should we ',
}
QUESTION_SUFFIX = '?'

def hipster_ipsum_ballot_question(prefix, suffix)
  question_range_max = \
    Ballot::MAX_QUESTION_LENGTH - prefix.length - suffix.length
  question_length = rand 20..question_range_max
  question = Faker::Hipster.paragraph_by_chars(characters: question_length)
    .delete('.') # Remove all periods
    .downcase
    .split[...-1] # Remove last word to ensure no partial words
    .join ' '
  "#{prefix}#{question}#{suffix}"
end

def create_fake_ballot(org, category:, isActive:)
  created_at = Faker::Time.between from: $simulation.started_at,
    to: $simulation.ended_at

  voting_ends_at = if isActive
    Faker::Time.between from: $simulation.ended_at,
      to: $simulation.ended_at + 2.weeks
  else
    Faker::Time.between from: created_at, to: $simulation.ended_at
  end

  encrypted_question = $simulation.encrypt hipster_ipsum_ballot_question(
    QUESTION_PREFIXES[category], QUESTION_SUFFIX)

  # Pick a random member who had joined by that time to be the creator
  creator = org.users.where(joined_at: ...created_at).sample

  Timecop.freeze created_at do
    creator.ballots.create! category: category,
      encrypted_question: encrypted_question,
      voting_ends_at: voting_ends_at
  end
end

inactive_yes_no_ballot_count = BALLOTS_DISTRIBUTION.call
active_yes_no_ballot_count = BALLOTS_DISTRIBUTION.call
inactive_multiple_choice_ballot_count = BALLOTS_DISTRIBUTION.call
active_multiple_choice_ballot_count = BALLOTS_DISTRIBUTION.call
ballot_count = [
  inactive_yes_no_ballot_count,
  active_yes_no_ballot_count,
  inactive_multiple_choice_ballot_count,
  active_multiple_choice_ballot_count,
].sum

print "\tCreating #{ballot_count} ballots... "
start_time = Time.now

org = User.find($simulation.founder_id).org

inactive_yes_no_ballot_count.times do
  create_fake_ballot org, category: :yes_no, isActive: false
end

active_yes_no_ballot_count.times do
  create_fake_ballot org, category: :yes_no, isActive: true
end

inactive_multiple_choice_ballot_count.times do
  create_fake_ballot org, category: :multiple_choice, isActive: false
end

active_multiple_choice_ballot_count.times do
  create_fake_ballot org, category: :multiple_choice, isActive: true
end

puts "Completed in #{(Time.now - start_time).round 3} s"
