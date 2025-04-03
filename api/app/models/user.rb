class User < ApplicationRecord
  include PgSearch::Model, Moderatable

  scope :joined_at_or_before, ->(time) { where(joined_at: ..time) }
  scope :left_org, -> { where.not(left_org_at: nil) }
  scope :officers, -> {
    # Must be used with with_service_stats scope
    where.not(min_office: nil)
  }
  scope :omit_left_org, -> { where(left_org_at: nil) }
  scope :order_by_office, ->(time) {
    # Must be used with with_service_stats scope
    order(:min_office, 'users.id')
  }
  scope :order_by_service, ->(time) {
    # Must be used with with_service_stats scope
    order(Arel.sql(User.sanitize_sql_array([
      %(
        (EXTRACT(EPOCH FROM(:time - users.joined_at)) / :time_division)
          + users.connection_count
          + (3 * users.recruit_count) DESC,
          users.id DESC
      ).squish,
      time: time,
      time_division: 1.month.to_i])))
  }
  scope :with_service_stats, ->(time = nil) {
    time ||= Time.now
    from(
      with(offices: Term.active_at(time)
        .group(:user_id)
        .select(
          :user_id,
          'array_agg(terms.office) AS offices_inner',
          'MIN(terms.office) AS min_office')
      ).left_outer_joins(:offices)
      .with(recruit_counts: User.joined_at_or_before(time)
        .group(:recruiter_id)
        .select('recruiter_id AS user_id, COUNT(*) AS recruit_count_inner')
      ).left_outer_joins(:recruit_counts)
      .with(scanned_counts: Connection.created_at_or_before(time)
        .group(:scanner_id)
        .select('scanner_id AS user_id, COUNT(*) AS scanned_count_inner')
      ).left_outer_joins(:scanned_counts)
      .with(shared_counts: Connection.created_at_or_before(time)
        .group(:sharer_id)
        .select('sharer_id AS user_id, COUNT(*) AS shared_count_inner')
      ).left_outer_joins(:shared_counts)
        .select(
          'users.*',
          'min_office',
          'COALESCE(offices_inner, ARRAY[]::integer[]) AS offices',
          'COALESCE(recruit_count_inner, 0) AS recruit_count',
          'COALESCE(scanned_count_inner, 0) + COALESCE(shared_count_inner, 0) AS connection_count',
        ),
      :users)
  }

  pg_search_scope :search_by_pseudonym,
    against: :pseudonym,
    using: :trigram,
    ranked_by: ":trigram"

  CORRUPTED_AUTH_TAG_VALUE = Base64.strict_encode64('0' * EncryptedMessage::BYTE_LENGTH_AUTH_TAG).freeze
  CORRUPTED_CIPHERTEXT_VALUE = Base64.strict_encode64('0').freeze
  PUBLIC_KEY_LENGTH = 178

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
  has_many :created_moderation_events,
    foreign_key: 'user_id',
    class_name: 'ModerationEvent'
  has_many :created_work_groups, class_name: 'WorkGroup'
  has_many :flags
  has_many :moderation_events, as: :moderatable
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

  has_one :union_card

  validates :org, presence: true, if: :will_save_change_to_left_org_at?
  validates :public_key_bytes,
    presence: true,
    length: { is: PUBLIC_KEY_LENGTH }
  validates :recruiter,
    same_org: { as: ->(user) { user }, name: 'Recruiter' },
    if: :recruiter

  before_update :on_join_org,
    if: -> { will_save_change_to_org_id? from: nil }

  def can?(scope)
    Permission.can? self, scope
  end

  def create_auth_token(expiration, scope)
    payload = JsonWebToken.payload(id, expiration, scope)
    JsonWebToken.encode(payload, private_key)
  end

  def public_key
    OpenSSL::PKey::EC.new(attributes['public_key_bytes'])
  end

  def public_key_bytes
    begin
      public_key.to_pem
    rescue
      nil
    end
  end

  def public_key_bytes=(value)
    begin
      write_attribute :public_key_bytes, OpenSSL::PKey::EC.new(value).to_der
    rescue
      write_attribute :public_key_bytes, nil
    end
  end

  def directly_connected_to?(user_id)
    Connection.directly_connected?(id, user_id)
  end

  def connection_to(user_id)
    Connection.between(id, user_id)
  end

  def leave_org
    return unless left_org_at.nil?

    now = Time.now

    transaction do
      [Comment, Post].each do |model|
        # Note that c and t must both be corrupted, instead of just c, because
        # otherwise messages that were literally '0' would still be decryptable.
        # Also note that no special handling of null is needed because
        # null || { any JSON } is still null.
        query_components = model.encrypted_attributes.map do |attribute|
          %(
            #{attribute} = #{attribute} || '{
              "c": "#{CORRUPTED_CIPHERTEXT_VALUE}",
              "t": "#{CORRUPTED_AUTH_TAG_VALUE}"
            }'
          ).squish
        end

        query_components.push("deleted_at = '#{now}'")

        query = query_components.join(', ')
        model.where(user_id: id).update_all query
      end

      terms.active_at(now).update_all accepted: false

      union_card&.destroy!

      update! left_org_at: now
    end
  end

  def my_vote_candidate_ids(ballot)
    votes.where(ballot_id: ballot.id)
      .order(created_at: :desc)
      .first
      &.candidate_ids || []
  end

  def offices
    office_numbers&.map { |o| Office.new(o).to_s }
  end

  def office_numbers
    attributes['offices'].sort
  end

  private

    attr_reader :private_key

    def on_join_org
      self.pseudonym = org.next_pseudonym
      self.joined_at = Time.current

      unless org.users.any?
        terms.build accepted: true,
          ends_at: 1000.years.from_now,
          office: :founder,
          starts_at: self.joined_at
      end
    end
end
