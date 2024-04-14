module Permission::Defaults
  DEFAULTS = {
    create_elections: {
      offices: ['founder', 'president', 'secretary'],
    },
  }.freeze

  DEFAULT_DEFAULT = {
    offices: ['founder', 'president'],
  }.freeze

  def self.[](key)
    DEFAULTS[key] || DEFAULT_DEFAULT
  end
end
