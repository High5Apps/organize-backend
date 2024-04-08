module Permission::Defaults
  DEFAULTS = {
    view_permissions: {
      offices: Office::TYPE_SYMBOLS,
    }
  }.freeze

  DEFAULT_DEFAULT = {
    offices: [:founder, :president],
  }.freeze

  def self.[](key)
    DEFAULTS[key] || DEFAULT_DEFAULT
  end
end
