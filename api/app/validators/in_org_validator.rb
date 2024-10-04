class InOrgValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value&.org_id
      record.errors.add attribute, options[:message] || 'must join an Org'
    end
  end
end
