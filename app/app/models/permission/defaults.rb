module Permission::Defaults
  DEFAULTS = {
    # TODO: Add a default for create_elections that includes secretary in
    # addition to the usual founder and president
    # create_elections: {
    #   offices: ['founder', 'president', 'secretary'],
    # },

    # TODO: Uncomment relevant tests in PermissionTest
  }.freeze

  DEFAULT_DEFAULT = {
    offices: ['founder', 'president'],
  }.freeze

  def self.[](key)
    DEFAULTS[key] || DEFAULT_DEFAULT
  end
end
