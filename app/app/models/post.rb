class Post < ApplicationRecord
  scope :created_before, ->(time) { where(created_at: ...time) }
  scope :left_outer_joins_with_most_recent_upvotes_created_before, ->(time) {
    joins(%Q(
      LEFT OUTER JOIN (
        #{Upvote.most_recent_created_before(time).to_sql}
      ) AS upvotes
        ON upvotes.post_id = posts.id
    ).gsub(/\s+/, ' '))
  }

  MAX_TITLE_LENGTH = 120
  MAX_BODY_LENGTH = 10000

  enum category: [:general, :grievances, :demands]

  belongs_to :org
  belongs_to :user

  has_many :comments
  has_many :upvotes

  validates :org, presence: true
  validates :category,
    presence: true,
    inclusion: { in: categories }
  validates :body,
    length: { maximum: MAX_BODY_LENGTH }
  validates :user, presence: true

  validate :encrypted_title_ciphertext_length_within_range

  before_validation :strip_whitespace
  after_create :create_upvote_for_user

  serialize :encrypted_title, EncryptedMessage

  private

  def create_upvote_for_user
    upvotes.create! user: user, value: 1
  end

  def encrypted_title_ciphertext_length_within_range
    length = encrypted_title.decoded_ciphertext_length
    return errors.add(:encrypted_title, "can't be blank") unless length > 0
    errors.add(:encrypted_title, 'is too long') if length > MAX_TITLE_LENGTH
  end

  def strip_whitespace
    body&.strip!
  end
end
