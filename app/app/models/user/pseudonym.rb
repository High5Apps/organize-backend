class User::Pseudonym
  attr_reader :adjectives, :animals

  def initialize(seed, adjectives: nil, animals: nil)
    @seed = seed
    @adjectives = adjectives || User::Pseudonyms::Adjectives::LIST_OF_100
    @animals = animals || User::Pseudonyms::Animals::LIST_OF_100
  end

  def at(index)
    i = shuffled_indices[index]
    adjective_i = i / @adjectives.length
    animal_i = i % @animals.length
    "#{@adjectives[adjective_i]} #{@animals[animal_i]}"
  end

  def to_a
    shuffled_indices.map { |i| at(i) }
  end

  def inspect
    "<#{self.class} @seed=#{@seed}>"
  end

  private

  def shuffled_indices
    return @shuffled_indices if @shuffled_indices

    size = @adjectives.length * @animals.length
    @shuffled_indices = (0...size).to_a
    @shuffled_indices.shuffle! random: Random.new(@seed)
  end
end
