class AfterCreatedAtValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # created_at is nil for records that haven't been created yet, so use
    # current time as an approximation
    created_at = record.created_at || Time.now

    if value.blank?
      message = options[:message] || "can't be blank"
      record.errors.add attribute, message
    elsif value <= created_at
      message = options[:message] || "can't be in the past"
      record.errors.add attribute, message
    end
  end
end
