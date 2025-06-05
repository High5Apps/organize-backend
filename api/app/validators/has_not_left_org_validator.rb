class HasNotLeftOrgValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value&.left_org_at?
      record.errors.add attribute, options[:message] || :left_org
    end
  end
end
