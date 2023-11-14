class Ballot::Query
  ALLOWED_ATTRIBUTES = [
    :category,
    :encrypted_question,
    :id,
    :voting_ends_at,
  ]

  def self.build(params={}, initial_ballots: nil)
    initial_ballots ||= Ballot.all

    ballots = initial_ballots.select(ALLOWED_ATTRIBUTES)

    ballots
  end
end
