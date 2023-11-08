class FutureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank?
      message = options[:message] || "can't be blank"
      record.errors.add attribute, message
    elsif value <= Time.now
      message = options[:message] || "can't be in the past"
      record.errors.add attribute, message
    end
  end
end
