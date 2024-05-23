class NotBlockedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value&.blocked?
      record.errors.add attribute, options[:message] || "can't be blocked"
    end
  end
end
