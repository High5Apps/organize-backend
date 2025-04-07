class ModerationEvent < ApplicationRecord
  scope :created_at_or_before, ->(time) { where(created_at: ..time) }

  scope :most_recent_created_at_or_before, ->(time) {
    from(
      select(%(
        DISTINCT ON (
          moderation_events.moderatable_type,
          moderation_events.moderatable_id
        ) moderation_events.*
      ).squish)
        .created_at_or_before(time)
        .order(%(
          moderation_events.moderatable_type,
          moderation_events.moderatable_id,
          moderation_events.created_at DESC
        ).squish),
    :moderation_events)
  }

  ALLOWED_TYPES = ['Ballot', 'Comment', 'Post', 'User']

  enum :action, [:allow, :block, :undo_allow, :undo_block], validate: true

  belongs_to :moderatable, polymorphic: true
  belongs_to :user

  validates :moderatable, same_org: { as: :user, name: 'Item' }
  validates :moderatable_type, inclusion: { in: ALLOWED_TYPES }
  validates :user, presence: true

  validate :action_transitions, on: :create
  validate :moderatable_flagged, unless: :moderatable_user?
  validate :not_blocking_impending_officer, on: :create, if: :moderatable_user?
  validate :not_blocking_officer, on: :create, if: :moderatable_user?

  after_save -> { moderatable.block }, if: :block?
  after_save -> { moderatable.unblock }, unless: :block?

  def moderatable_user?
    moderatable_type == 'User'
  end

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

  def not_blocking_impending_officer
    return unless moderatable

    if moderatable.terms.impending_at(Time.now).any?
      errors.add :base, "Can't block impending officers"
    end
  end

  def not_blocking_officer
    return unless moderatable

    if moderatable.terms.active_at(Time.now).any?
      errors.add :base, "Can't block officers"
    end
  end
end
