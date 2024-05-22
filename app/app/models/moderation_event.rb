class ModerationEvent < ApplicationRecord
  scope :most_recent_created_at_or_before, ->(time) {
    select(%(
      DISTINCT ON (
        moderation_events.moderatable_type,
        moderation_events.moderatable_id
      ) moderation_events.*
    ).gsub(/\s+/, ' '))
      .where(created_at: ..time)
      .order(%(
        moderation_events.moderatable_type,
        moderation_events.moderatable_id,
        moderation_events.created_at DESC
      ).gsub(/\s+/, ' '))
  }

  ALLOWED_TYPES = ['Ballot', 'Comment', 'Post', 'User']

  enum :action, [:allow, :block, :undo_allow, :undo_block], validate: true

  belongs_to :moderatable, polymorphic: true
  belongs_to :user

  validates :moderatable_type, inclusion: { in: ALLOWED_TYPES }
  validates :user, presence: true
  validates :user,
    same_org: { as: ->(event) { event.moderatable&.user}, name: 'Item' },
    unless: :moderatable_user?
  validates :user, same_org: :moderatable, if: :moderatable_user?

  validate :action_transitions, on: :create
  validate :moderatable_flagged, unless: :moderatable_user?

  after_save -> { moderatable.block }, if: :block?
  after_save -> { moderatable.unblock }, unless: :block?

  private

  def action_transitions
    return unless moderatable

    last_action = moderatable.moderation_events.last&.action
    allowed_actions = case last_action
    when nil, 'undo_allow', 'undo_block'
      ['allow', 'block']
    when 'allow'
      ['undo_allow']
    when 'block'
      ['undo_block']
    else
      []
    end

    unless allowed_actions.include? action
      errors.add :action,
        "can't be #{action.inspect} when then last action was #{last_action.inspect}. Another moderator probably moderated this item just now."
    end
  end

  def moderatable_flagged
    return unless moderatable

    unless moderatable.respond_to?(:flags) && moderatable.flags.any?
      errors.add :base, "can't moderate an item that isn't flagged"
    end
  end

  def moderatable_user?
    moderatable_type == 'User'
  end
end
