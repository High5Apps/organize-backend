class Office
  TYPE_SYMBOLS = [
    :founder,
    :president,
    :vice_president,
    :secretary,
    :treasurer,
    :steward,
    :trustee,
  ]
  TYPE_STRINGS = TYPE_SYMBOLS.map(&:to_s)
  TYPE_TITLES = TYPE_STRINGS.map(&:titleize)

  def initialize(index)
    @index = index
  end

  def title
    TYPE_TITLES[@index]
  end

  def to_s
    TYPE_STRINGS[@index]
  end

  def to_sym
    TYPE_SYMBOLS[@index]
  end
end
