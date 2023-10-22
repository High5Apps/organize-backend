# https://www.wolframalpha.com/input?i=beta+distribution+%282%2C+19%29
UPVOTES_DISTRIBUTION = Rubystats::BetaDistribution.new(2, 19)

# https://www.wolframalpha.com/input?i=beta+distribution+%281%2C+20%29
DOWNVOTES_DISTRIBUTION = Rubystats::BetaDistribution.new(1, 20)

def create_upvotes(parent_relation, user_ids)
  user_count = user_ids.count

  parent_relation_count = parent_relation.count
  expected_upvote_count = \
    (parent_relation_count * user_count * UPVOTES_DISTRIBUTION.mean).round
  expected_downvote_count = \
    (parent_relation_count * user_count * DOWNVOTES_DISTRIBUTION.mean).round
  parent_model = parent_relation.klass
  type = parent_model.to_s.downcase

  print "\tCreating roughly #{expected_upvote_count} #{type} upvotes and #{expected_downvote_count} #{type} downvotes... "
  start_time = Time.now

  columns = [
    :value, :user_id, ActiveSupport::Inflector.foreign_key(parent_model),
  ]
  values = []

  parent_relation.all.each do |pm|
    upvotes = (user_count * UPVOTES_DISTRIBUTION.rng).round
    downvotes = ((user_count - upvotes) * DOWNVOTES_DISTRIBUTION.rng).round
    shuffled_user_ids = user_ids.shuffle
    upvoter_ids = shuffled_user_ids[0, upvotes]
    values += upvoter_ids.map { |id| columns.zip([1, id, pm.id]).to_h }
    downvoter_ids = shuffled_user_ids[upvotes, downvotes]
    values += downvoter_ids.map { |id| columns.zip([-1, id, pm.id]).to_h }
  end

  Upvote.insert_all values unless values.empty?

  puts "Completed in #{(Time.now - start_time).round 3} s"
end

org = User.find($simulation.founder_id).org
user_ids = org.users.ids

create_upvotes org.posts, user_ids
create_upvotes Comment.where(post_id: org.posts), user_ids
