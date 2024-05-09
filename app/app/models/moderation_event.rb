class ModerationEvent < ApplicationRecord
  enum :action, [:allow, :block, :undo_allow, :undo_block], validate: true

  belongs_to :ballot, optional: true
  belongs_to :comment, optional: true
  belongs_to :post, optional: true
  belongs_to :moderator, class_name: 'User'
  belongs_to :user, optional: true

  validates :moderator, presence: true
  validates :moderator,
    same_org: { as: ->(event) { event.item&.user }, name: 'Item' },
    unless: :user_id
  validates :user, same_org: :moderator, if: :user_id

  validate :action_transitions, on: :create
  validate :exactly_one_item
  validate :item_flagged, unless: -> { user_id }

  def item
    non_nil_items = item_ids.compact
    return nil unless non_nil_items.count == 1

    case non_nil_items.first
    when ballot_id
      ballot
    when comment_id
      comment
    when post_id
      post
    when user_id
      user
    end
  end

  def item=(updated_item)
    self.ballot_id = nil
    self.comment_id = nil
    self.post_id = nil
    self.user_id = nil

    case updated_item.class.name
    when 'Ballot'
      self.ballot_id = updated_item.id
    when 'Comment'
      self.comment_id = updated_item.id
    when 'Post'
      self.post_id = updated_item.id
    when 'User'
      self.user_id = updated_item.id
    else
      raise 'unexpected item class'
    end
  end

  private

  def action_transitions
    return unless item

    last_item_action = item.moderation_events.last&.action
    allowed_actions = case last_item_action
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
        "can't be #{action.inspect} when then last action was #{last_item_action.inspect}. Another moderator probably moderated this item just now."
    end
  end

  def exactly_one_item
    unless item
      errors.add :base, 'must have exactly one item'
    end
  end

  def item_flagged
    return unless item

    unless item.flagged_items.any?
      errors.add :base, "can't moderate an item that isn't flagged"
    end
  end

  def item_ids
    [ballot_id, comment_id, post_id, user_id]
  end
end
