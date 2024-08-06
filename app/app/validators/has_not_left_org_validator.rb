class HasNotLeftOrgValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value&.left_org_at?
      record.errors.add attribute,
        options[:message] || "can't have left the Org"
    end
  end
end
