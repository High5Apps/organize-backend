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
    raise ActiveRecord::RecordNotFound unless org

    if office && !office.is_a?(String)
      raise 'office param must be a string'
    end

    now = Time.now
    elections = org.ballots.election

    # It's not open if there's already an election in nominations
    in_nominations = elections.in_nominations(now).pluck(:office)

    # It's not open if there's already an active election with candidates
    active_with_candidates = elections.active_at(now)
      .where.associated(:candidates).pluck(:office)

    # It's not open if there's an election awaiting term acceptance by a winner
    awaiting_acceptance = elections
      .in_term_acceptance_period(now)
      .to_a
      .filter { |election| election.winners.count > 0 }
      .map {|election| election[:office] }

    # It's not open if there's already an active term that's before of its
    # cooldown period. (Doesn't apply to stewards, since there can be multiple.)
    filled_and_before_cooldown = org.terms
      .active_at(now + Term::COOLDOWN_PERIOD)
      .pluck(:office) - ['steward']

    office_types = Office::TYPE_STRINGS
    open_offices = office_types - in_nominations - active_with_candidates -
      awaiting_acceptance - filled_and_before_cooldown - ['founder']

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
