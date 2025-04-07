class SameOrgValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    is_other_value_symbol = options[:with].instance_of?(Symbol) ||
      options[:as].instance_of?(Symbol)
    raise 'unexpected options' unless is_other_value_symbol


    is_other_value_self = options[:with] === :self || options[:as] === :self
    if is_other_value_self
      other_org = record.org
    else
      other_attribute = options[:with] || options[:as]
      other_value = record.send(other_attribute)
      other_org = other_value&.org
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

    org = value&.org

    unless org && (org == other_org)
      record.errors.add error_attribute, message
    end
  end
end
