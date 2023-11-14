class Ballot::Query
  ALLOWED_ATTRIBUTES = [
    :category,
    :encrypted_question,
    :id,
    :voting_ends_at,
  ]

  def self.build(params={}, initial_ballots: nil)
    initial_ballots ||= Ballot.all

    created_before_param = params[:created_before] || Time.now
    created_before = Time.parse(created_before_param.to_s).utc

    ballots = initial_ballots
      .created_before(created_before)
      .select(ALLOWED_ATTRIBUTES)

    ballots
  end
end
