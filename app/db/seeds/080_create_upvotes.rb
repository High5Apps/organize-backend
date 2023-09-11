# https://www.wolframalpha.com/input?i=beta+distribution+%282%2C+19%29
UPVOTES_DISTRIBUTION = Rubystats::BetaDistribution.new(2, 19)

# https://www.wolframalpha.com/input?i=beta+distribution+%281%2C+20%29
DOWNVOTES_DISTRIBUTION = Rubystats::BetaDistribution.new(1, 20)

user_ids = User.ids
user_count = user_ids.count
post_count = Post.count
expected_upvote_count = \
  (post_count * user_count * UPVOTES_DISTRIBUTION.mean).round
expected_downvote_count = \
  (post_count * user_count * DOWNVOTES_DISTRIBUTION.mean).round

print "\tCreating roughly #{expected_upvote_count} upvotes and #{expected_downvote_count} downvotes... "
start_time = Time.now

columns = [:value, :user_id, :post_id]
values = []

Post.all.each do |p|
  upvotes = (user_count * UPVOTES_DISTRIBUTION.rng).round
  downvotes = ((user_count - upvotes) * DOWNVOTES_DISTRIBUTION.rng).round
  shuffled_user_ids = user_ids.shuffle
  upvoter_ids = shuffled_user_ids[0, upvotes]
  values += upvoter_ids.map { |id| columns.zip([1, id, p.id]).to_h }
  downvoter_ids = shuffled_user_ids[upvotes, downvotes]
  values += downvoter_ids.map { |id| columns.zip([-1, id, p.id]).to_h }
end

UpVote.insert_all values unless values.empty?

puts "Completed in #{(Time.now - start_time).round 3} s"
