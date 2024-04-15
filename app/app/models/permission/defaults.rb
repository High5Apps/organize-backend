module Permission::Defaults
  DEFAULTS = {
    create_elections: {
      offices: ['founder', 'president', 'secretary'],
    },
    edit_org: {
      offices: ['founder', 'president', 'secretary'],
    },
  }.with_indifferent_access.freeze

  DEFAULT_DEFAULT = {
    offices: ['founder', 'president'],
  }.freeze

  def self.[](key)
    DEFAULTS[key] || DEFAULT_DEFAULT
  end
end
