class Ballot < ApplicationRecord
  include Encryptable

  scope :active_at, ->(time) { where.not(voting_ends_at: ..time) }
  scope :created_before, ->(time) { where(created_at: ...time) }
  scope :inactive_at, ->(time) { where(voting_ends_at: ..time) }
  scope :order_by_active, -> {
    # Order by the earlier of nominations_end_at (if it exists) and
    # voting_ends_at, then break ties by lowest id
    order(Arel.sql(%(
      LEAST(
        COALESCE(ballots.nominations_end_at, DATE 'infinity'),
        ballots.voting_ends_at
      ) ASC,
      ballots.id ASC
    ).gsub(/\s+/, ' ')))
  }
  scope :order_by_inactive, -> { order(voting_ends_at: :desc, id: :desc) }

  MAX_QUESTION_LENGTH = 140

  enum category: [:yes_no, :multiple_choice, :election]
  enum office: Office::TYPE_SYMBOLS

  belongs_to :user

  has_many :candidates
  has_many :nominations
  has_many :votes

  has_one :org, through: :user

  validates :category,
    presence: true,
    inclusion: { in: categories }
  validates :max_candidate_ids_per_vote,
    numericality: { allow_nil: true, greater_than: 0, only_integer: true }
  validates :max_candidate_ids_per_vote,
    numericality: { allow_nil: true, equal_to: 1 },
    if: :yes_no?
  validates :max_candidate_ids_per_vote,
    numericality: { allow_nil: true, equal_to: 1 },
    if: :election?,
    unless: -> { office == 'steward' }
  validates :office, inclusion: { in: offices }, if: :election?
  validates :office, absence: true, unless: :election?
  validates :nominations_end_at,
    presence: true,
    after_created_at: true,
    if: :election?
  validates :nominations_end_at, absence: true, unless: :election?
  validates :user, presence: true
  validates :term_ends_at,
    presence: true,
    comparison: {
      greater_than: :voting_ends_at,
      message: 'must be after voting end',
    },
    if: :election?
  validates :term_ends_at, absence: true, unless: :election?
  validates :voting_ends_at, presence: true
  validates :voting_ends_at, after_created_at: true, unless: :election?
  validates :voting_ends_at,
    comparison: {
      greater_than: :nominations_end_at,
      message: 'must be after nominations end',
    },
    if: :election?

  validate :office_open, on: :create, if: :election?

  has_encrypted :question, present: true, max_length: MAX_QUESTION_LENGTH

  def results
    results = candidates
      .left_outer_joins_with_most_recent_unnested_votes
      .group(:id)
      .order(count_unnested_candidate_id: :desc, id: :desc)
      # Note that it's important to count :unnested_candidate_id instead of :all
      # or :candidate_id, because of the left join. Otherwise, every candidate
      # would receive at least one vote.
      .count(:unnested_candidate_id)
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

  private

  def office_open
    unless Office.availability_in(org, office)[:open]
      errors.add :office, 'is already filled or currently has an open election'
    end
  end
end
