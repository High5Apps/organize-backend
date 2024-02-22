# The Pareto distribution below is unbounded and can sometimes be more than
# 1000. This cap helps to guard against those rare and unrealistic scenarios.
MAX_COMMENTS_PER_POST = 100

# 1.161 is the required alpha for the 80/20 Pareto distribution. With it, 20%
# of posts will receive 80% of comments. 1.161 approximately equals log4_5. See
# https://en.wikipedia.org/wiki/Pareto_distribution#Relation_to_the_%22Pareto_principle%22
COMMENTS_ON_POST_DISTRIBUTION = -> {
  [(1 / (rand**(1 / 1.161)) - 1).round, MAX_COMMENTS_PER_POST].min
}

# This isn't statistically or mathematically correct, but it seems pretty close
APPROXIMATE_COMMENTS_PER_POST = 2.5

# https://www.wolframalpha.com/input?i=beta+distribution+%282%2C+50%29
CHARACTERS_IN_COMMENT_DISTRIBUTION = Rubystats::BetaDistribution.new(2, 50)

# https://www.wolframalpha.com/input?i=beta+distribution+%281%2C+2%29
ELAPSED_TIME_DISTRIBUTION = Rubystats::BetaDistribution.new(1, 2)

def hipster_ipsum_comment_body
  approximate_body_length = \
    MAX_CHARACTERS_IN_BODY * CHARACTERS_IN_COMMENT_DISTRIBUTION.rng
  paragraph_count = rand 1..3
  max_characters_per_paragraph = approximate_body_length / paragraph_count

  paragraphs = (0...paragraph_count).map do
    characters = \
      [MIN_CHARACTERS_PER_PARAGRAPH, max_characters_per_paragraph].max
    p = Faker::Hipster.paragraph_by_chars(characters:)

    # Remove the final sentence to ensure no partial words
    p.delete_suffix! '.' # Remove the final period
    p = p[0..p.rindex('.')] # Remove the last sentence
  end

  paragraphs.join "\n\n"
end

org = User.find($simulation.founder_id).org
users = org.users
posts = org.posts
comment_count_estimate = posts.count * APPROXIMATE_COMMENTS_PER_POST
print "\tCreating roughly #{comment_count_estimate.round} comments... "
start_time = Time.now

posts.order(:created_at).each do |post|
  comment_count = COMMENTS_ON_POST_DISTRIBUTION.call
  next unless comment_count > 0

  available_timespan = $simulation.ended_at - post.created_at
  max_average_time_between_comments = available_timespan / comment_count
  current_time = post.created_at

  potential_parent_comments = []

  comment_count.times do
    # Pick a random amount of time to have elappsed since the last comment
    time_delta = \
      max_average_time_between_comments * ELAPSED_TIME_DISTRIBUTION.rng
    comment_time = current_time + time_delta

    # Pick a random member who had joined by that time to be the commenter
    commenter = users.where(joined_at: ...comment_time).sample

    if rand < 0.8 && !potential_parent_comments.empty?
      parent = potential_parent_comments.sample
      next if parent.depth + 1 >= Comment::MAX_COMMENT_DEPTH
    end

    travel_to comment_time do
      comment = post.comments.create!(user: commenter,
        encrypted_body: $simulation.encrypt(hipster_ipsum_comment_body),
        parent:)
      potential_parent_comments.push(comment)
    end
  end
end

puts "Completed in #{(Time.now - start_time).round 3} s"
