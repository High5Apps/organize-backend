class Office
  TYPE_SYMBOLS = [
    :founder,
    :president,
    :vice_president,
    :secretary,
    :treasurer,
    :steward,
    :trustee,
  ]
  TYPE_STRINGS = TYPE_SYMBOLS.map(&:to_s)
  TYPE_TITLES = TYPE_STRINGS.map(&:titleize)

  def initialize(index)
    @index = index
  end

  def title
    TYPE_TITLES[@index]
  end

  def to_s
    TYPE_STRINGS[@index]
  end

  def to_sym
    TYPE_SYMBOLS[@index]
  end

  def self.availability_in org, office=nil
    if office && !office.is_a?(String)
      raise 'office param must be a string'
    end

    now = Time.now
    elections = org.ballots.election

    # It's not open if there's already an active election for the office
    active_election_offices = elections.active_at(now).pluck(:office)

    # It's not open if there's an election awaiting term acceptance by a winner
    elections_awaiting_acceptance = elections
      .in_term_acceptance_period(now)
      .to_a
      .filter { |election| election.winners.count > 0 }
      .map {|election| election[:office] }

    # It's not open if there's already a term that's outside of its cooldown
    # period. (Doesn't apply to stewards, since there can be multiple.)
    filled_offices_outside_cooldown = org.terms
      .active_at(now + Term::COOLDOWN_PERIOD)
      .pluck(:office) - ['steward']

    office_types = Office::TYPE_STRINGS
    open_offices = \
      office_types - filled_offices_outside_cooldown - active_election_offices \
      - elections_awaiting_acceptance

    offices = office_types.map do |type|
      open = open_offices.include?(type)
      { type:, open: }
    end

    if office
      offices.filter{ |o| o[:type] == office }.first
    else
      offices
    end
  end
end
