class SameOrgValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if options[:with].instance_of? Symbol
      error_attribute = attribute

      other_attribute = options[:with]
      other_value = record.send(other_attribute)
      other_org = (other_attribute == :org) ? other_value : other_value&.org
    elsif options[:as].instance_of?(Proc) && options[:name].instance_of?(String)
      error_attribute = :base

      other_value = options[:as].call(record)
      other_org = other_value&.org
    else
      raise 'unexpected options'
    end

    message = options[:message] || 'not found'
    if options[:as]
      message = "#{options[:name]} #{message}"
    end

    org = (attribute == :org) ? value : value&.org

    unless org && (org == other_org)
      record.errors.add error_attribute, message
    end
  end
end
