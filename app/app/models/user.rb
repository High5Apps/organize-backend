class User < ApplicationRecord
  scope :joined_before, ->(time) { where(joined_at: ...time) }
  scope :with_offices, -> {
    from(
      joins("LEFT OUTER JOIN (#{
        joins(:terms).group(:id)
          .select(
            'users.id AS user_id, array_agg(terms.office) AS offices_inner')
          .to_sql
      }) AS offices ON users.id = offices.user_id")
        .select('*', 'COALESCE(offices_inner, ARRAY[]::integer[]) AS offices'),
      :users)
  }
  scope :with_recruit_count, -> {
    from(
      joins("LEFT OUTER JOIN (#{
        joins(:recruits).group(:id)
          .select('users.id AS user_id, COUNT(*) AS recruit_count_inner')
          .to_sql
      }) AS recruit_counts ON users.id = recruit_counts.user_id")
        .select('*', 'COALESCE(recruit_count_inner, 0) AS recruit_count'),
      :users)
  }

  PUBLIC_KEY_LENGTH = 91

  attr_writer :private_key

  belongs_to :org, optional: true
  belongs_to :recruiter,
    class_name: 'User',
    foreign_key: 'recruiter_id',
    optional: true

  has_many :ballots
  has_many :candidates
  has_many :comments
  has_many :created_nominations,
    foreign_key: 'nominator_id',
    class_name: 'Nomination'
  has_many :posts
  has_many :received_nominations,
    foreign_key: 'nominee_id',
    class_name: 'Nomination'
  has_many :recruits, foreign_key: 'recruiter_id', class_name: 'User'
  has_many :scanned_connections,
    foreign_key: 'scanner_id',
    class_name: 'Connection'
  has_many :shared_connections,
    foreign_key: 'sharer_id',
    class_name: 'Connection'
  has_many :terms
  has_many :upvotes
  has_many :votes

  has_many :scanners, through: :shared_connections
  has_many :sharers, through: :scanned_connections

  validates :public_key_bytes,
    presence: true,
    length: { is: PUBLIC_KEY_LENGTH }

  before_validation :convert_public_key_to_binary, on: :create
  before_update :on_join_org,
    if: -> { will_save_change_to_org_id? from: nil }

  def create_auth_token(expiration, scope)
    payload = JsonWebToken.payload(id, expiration, scope)
    JsonWebToken.encode(payload, private_key)
  end

  def public_key
    OpenSSL::PKey::EC.new(public_key_bytes)
  end

  def directly_connected_to?(user_id)
    Connection.directly_connected?(id, user_id)
  end

  def connection_to(user_id)
    Connection.between(id, user_id)
  end

  def my_vote_candidate_ids(ballot)
    votes.where(ballot_id: ballot.id)
      .order(created_at: :desc)
      .first
      &.candidate_ids || []
  end

  private

    attr_reader :private_key

    def convert_public_key_to_binary
      begin
        public_key_bytes = OpenSSL::PKey::EC.new(self.public_key_bytes).to_der
        self.public_key_bytes = public_key_bytes
      rescue => exception
        self.public_key_bytes = nil
      end
    end

    def on_join_org
      self.pseudonym = org.next_pseudonym
      self.joined_at = Time.current

      unless org.users.any?
        terms.build ends_at: 1000.years.from_now, office: :founder
      end
    end
end
