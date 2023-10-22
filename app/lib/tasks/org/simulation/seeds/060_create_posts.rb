# These should add to 1.0
CATEGORY_FRACTIONS = {
  general: 0.6,
  grievances: 0.25,
  demands: 0.15,
}

# https://www.wolframalpha.com/input?i=beta+distribution+%282%2C+20%29
CHARACTERS_IN_BODY_DISTRIBUTION = Rubystats::BetaDistribution.new(2, 20)

MAX_CHARACTERS_IN_BODY = Post::MAX_BODY_LENGTH
MIN_CHARACTERS_PER_PARAGRAPH = 20
MAX_PARAGRAPH_COUNT = 10
POSTS_WITHOUT_BODY_FRACTION = 0.5
TITLE_CHARACTER_RANGE = 20..Post::MAX_TITLE_LENGTH

post_data = $simulation.to_seed_data[:posts]

print "\tCreating #{post_data.count} posts... "
start_time = Time.now

org = User.find($simulation.founder_id).org

def random_time_during_day(timestamp)
  Faker::Time.between from: timestamp.at_midnight,
    to: timestamp.at_midnight + 1.day
end

def random_category
  cumulative_fraction = 0
  @sorted_category_cdf = @sorted_category_cdf ||
    CATEGORY_FRACTIONS.sort_by {|k, v| v}.map do |category, fraction|
      cumulative_fraction += fraction
      [category, cumulative_fraction]
    end

  r = rand
  @sorted_category_cdf.each do |category, cumulative_fraction|
    return category if r < cumulative_fraction
  end
end

def hipster_ipsum_post_title
  title_length = rand TITLE_CHARACTER_RANGE
  title = Faker::Hipster.paragraph_by_chars characters: title_length
  title = title.delete '.' # Remove all periods
  split_title = title.split
  split_title.pop # Remove last word to ensure no partial words
  title = split_title.join ' '
end

def hipster_ipsum_post_body
  return if rand < POSTS_WITHOUT_BODY_FRACTION

  approximate_body_length = \
    MAX_CHARACTERS_IN_BODY * CHARACTERS_IN_BODY_DISTRIBUTION.rng
  paragraph_count = rand 1..MAX_PARAGRAPH_COUNT
  max_characters_per_paragraph = approximate_body_length / paragraph_count

  paragraphs = (0...paragraph_count).map do
    characters = \
      [MIN_CHARACTERS_PER_PARAGRAPH, max_characters_per_paragraph].max
    p = Faker::Hipster.paragraph_by_chars characters: characters

    # Remove the final sentence to ensure no partial words
    p.delete_suffix! '.' # Remove the final period
    p = p[0..p.rindex('.')] # Remove the last sentence
  end

  paragraphs.join "\n\n"
end

post_data.each do |user_id, day_start|
  created_at = random_time_during_day day_start

  Timecop.freeze created_at do
    User.find(user_id).posts.create! category: random_category.to_s,
      title: hipster_ipsum_post_title,
      body: hipster_ipsum_post_body,
      org: org
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
