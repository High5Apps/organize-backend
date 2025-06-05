class Permission::Data
  include ActiveModel::API

  KEYS = [:offices]

  attr_accessor *KEYS

  validates :offices, presence: true

  validate :offices_only_includes_offices
  validate :no_duplicate_offices

  def attributes
    instance_values
  end

  def self.dump(value)
    value.blank? ? nil : value.as_json
  end

  def self.load(hash)
    filtered_hash = hash&.slice *KEYS.map(&:to_s)
    Permission::Data.new filtered_hash
  end

  private

  def no_duplicate_offices
    return unless offices

    unless offices.uniq.length == offices.length
      errors.add :offices, :contains_duplicates
    end
  end

  def offices_only_includes_offices
    return unless offices
    unless offices.all? { |office| Office::TYPE_STRINGS.include? office }
      errors.add :offices, :includes_non_offices
    end
  end
end
