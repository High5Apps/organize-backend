class PermissionData
  include ActiveModel::API

  attr_accessor :offices

  validates :offices, presence: true

  validate :offices_only_includes_offices

  def attributes
    instance_values
  end

  def self.dump(value)
    if value.respond_to? :attributes
      value.attributes
    else
      value.to_h
    end
  end

  def self.load(hash)
    PermissionData.new(hash)
  end

  private

  def offices_only_includes_offices
    return unless offices
    unless offices.all? { |office| Office::TYPE_STRINGS.include? office }
      errors.add(:offices, 'must only include offices')
    end
  end
end
