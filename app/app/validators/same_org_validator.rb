class SameOrgValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    is_other_value_symbol = options[:with].instance_of?(Symbol) ||
      options[:as].instance_of?(Symbol)
    is_other_value_proc = options[:as].instance_of?(Proc)
    has_message_info = options[:name].instance_of?(String) ||
      options[:message].instance_of?(String)

    if is_other_value_symbol
      other_attribute = options[:with] || options[:as]
      other_value = record.send(other_attribute)
      other_org = (other_attribute == :org) ? other_value : other_value&.org
    elsif is_other_value_proc && has_message_info
      other_value = options[:as].call(record)
      other_org = other_value&.org
    else
      raise 'unexpected options'
    end

    if options[:message] || options[:name]
      error_attribute = :base
    else
      error_attribute = attribute
    end

    if options[:message]
      message = options[:message]
    elsif options[:name]
      message = "#{options[:name]} not found"
    else
      message = 'not found'
    end

    org = (attribute == :org) ? value : value&.org

    unless org && (org == other_org)
      record.errors.add error_attribute, message
    end
  end
end
