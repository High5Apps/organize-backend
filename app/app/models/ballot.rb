class Ballot < ApplicationRecord
  include Encryptable
  include Flaggable

  scope :active_at, ->(time) { where.not(voting_ends_at: ..time) }
  scope :created_at_or_before, ->(time) { where(created_at: ..time) }
  scope :inactive_at, ->(time) { where(voting_ends_at: ..time) }
  scope :in_nominations, ->(time) {
    election.where.not(nominations_end_at: ..time)
  }
  scope :in_term_acceptance_period, ->(time) {
    election.inactive_at(time).where.not(term_starts_at: ..time)
  }
  scope :order_by_active, ->(time) {
    # If in nominations, use nomination_end, otherwise use voting_end
    # Break ties by lowest id
    order(Arel.sql(Ballot.sanitize_sql_array([
      %(
        CASE
          WHEN :time < ballots.nominations_end_at
            THEN ballots.nominations_end_at
          ELSE ballots.voting_ends_at
        END ASC,
        ballots.id ASC
      ).gsub(/\s+/, ' '),
      time:])))
  }
  scope :order_by_inactive, -> { order(voting_ends_at: :desc, id: :desc) }

  MAX_QUESTION_LENGTH = 140
  MIN_TERM_ACCEPTANCE_PERIOD = 24.hours

  enum :category, [:yes_no, :multiple_choice, :election], validate: true
  enum :office, Office::TYPE_SYMBOLS, validate: { allow_nil: true }

  has_many :candidates
  has_many :nominations
  has_many :terms
  has_many :votes

  has_one :org, through: :user

  validates :max_candidate_ids_per_vote,
    numericality: { allow_nil: true, greater_than: 0, only_integer: true }
  validates :max_candidate_ids_per_vote,
    numericality: { allow_nil: true, equal_to: 1 },
    if: :yes_no?
  validates :max_candidate_ids_per_vote,
    numericality: { allow_nil: true, equal_to: 1 },
    if: :election?,
    unless: -> { office == 'steward' }
  validates :office, presence: true, if: :election?
  validates :office, absence: true, unless: :election?
  validates :nominations_end_at,
    presence: true,
    after_created_at: true,
    if: :election?
  validates :nominations_end_at, absence: true, unless: :election?
  validates :user, in_org: true
  validates :term_ends_at,
    presence: true,
    comparison: { greater_than: :term_starts_at },
    if: :election?
  validates :term_ends_at, absence: true, unless: :election?
  validates :term_starts_at,
      presence: true,
      comparison: {
        greater_than_or_equal_to: ->(ballot) {
          ballot.voting_ends_at + MIN_TERM_ACCEPTANCE_PERIOD } },
      if: :election?
  validates :term_starts_at, absence: true, unless: :election?
  validates :voting_ends_at, presence: true
  validates :voting_ends_at, after_created_at: true, unless: :election?
  validates :voting_ends_at,
    comparison: { greater_than: :nominations_end_at },
    if: :election?

  validate :office_open, on: :create, if: :election?
  validate :term_starts_at_is_not_before_the_previous_term_ends_for_non_stewards,
    on: :create,
    if: :election?

  has_encrypted :question, present: true, max_length: MAX_QUESTION_LENGTH
  flaggable title: :encrypted_question

  def results
    results = candidates
      .left_outer_joins_with_unnested_votes
      .group(:id)
      .order(count_candidate_id: :desc, id: :desc)
      # Note that it's important to count :candidate_id instead of :all because
      # of the left join. Otherwise, every candidate would receive at least one
      # vote.
      .count(:candidate_id)
      .map { |candidate_id, vote_count| { candidate_id:, vote_count: } }

    # Downrank considering ties. Lower rank is better. Zero is the best.
    # A candidate is a winner iff its rank is strictly less than the ballot's
    # max_candidate_ids_per_vote.
    # Iterate results from least to highest vote-receivers:
    # - The lowest vote-receiver automatically receives the highest/worst rank,
    #   equal to the number of candidates - 1
    # - For successive candidates:
    #   - If the candidate tied with the next worst candidate, the candidate's
    #     rank is set equal to the next worst candidate's rank
    #   - Otherwise, the candidate's rank is set to its ideal rank, which is its
    #     index in the results sorted from best to worst. "Ideal" because this
    #     rank would have been its rank if ties weren't considered.
    reversed_results = results.reverse
    reversed_results.each_with_index do |result, i|
      rank = results.count - 1 - i
      next_worst_result = (i - 1) < 0 ? nil : reversed_results[i - 1]
      if next_worst_result
        is_tied_with_next_worst_result = \
          next_worst_result[:vote_count] == result[:vote_count]
        if is_tied_with_next_worst_result
          rank = next_worst_result[:rank]
        end
      end

      result[:rank] = rank
    end

    reversed_results.reverse
  end

  def voting_ended?
    Time.now >= voting_ends_at
  end

  def winners
    results.filter{ |result| result[:rank] < max_candidate_ids_per_vote }
  end

  def winner?(candidate_id)
    winners.map{ |winner| winner[:candidate_id] }.include? candidate_id
  end

  private

  def office_open
    unless Office.availability_in(org, office)[:open]
      errors.add :office, 'is already filled or currently has an open election'
    end
  end

  def term_starts_at_is_not_before_the_previous_term_ends_for_non_stewards
    return unless term_starts_at && office
    return if office === 'steward'

    if org.terms.where(office:).active_at(term_starts_at).exists?
      errors.add :term_starts_at, "can't be before the previous term ends"
    end
  end
end
