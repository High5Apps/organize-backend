class SameOrgValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if options[:with].instance_of? Symbol
      error_attribute = attribute

      other_value_attribute = options[:with]
      other_value = record.send(other_value_attribute)
    elsif options[:as].instance_of?(Proc) && options[:name].instance_of?(String)
      error_attribute = :base

      other_value = options[:as].call(record)
    else
      raise 'unexpected options'
    end

    message = options[:message] || 'not found'
    if options[:as]
      message = "#{options[:name]} #{message}"
    end

    unless value&.org && (value&.org == other_value&.org)
      record.errors.add error_attribute, message
    end
  end
end
