# https://www.wolframalpha.com/input?i=beta+distribution+%282%2C+19%29
UPVOTES_DISTRIBUTION = Rubystats::BetaDistribution.new(2, 19)

# https://www.wolframalpha.com/input?i=beta+distribution+%281%2C+20%29
DOWNVOTES_DISTRIBUTION = Rubystats::BetaDistribution.new(1, 20)

USER_IDS = User.ids
USER_COUNT = USER_IDS.count

def create_upvotes(parent_model)
  parent_model_count = parent_model.count
  expected_upvote_count = \
    (parent_model_count * USER_COUNT * UPVOTES_DISTRIBUTION.mean).round
  expected_downvote_count = \
    (parent_model_count * USER_COUNT * DOWNVOTES_DISTRIBUTION.mean).round
  type = parent_model.to_s.downcase

  print "\tCreating roughly #{expected_upvote_count} #{type} upvotes and #{expected_downvote_count} #{type} downvotes... "
  start_time = Time.now

  columns = [
    :value, :user_id, ActiveSupport::Inflector.foreign_key(parent_model),
  ]
  values = []

  parent_model.all.each do |pm|
    upvotes = (USER_COUNT * UPVOTES_DISTRIBUTION.rng).round
    downvotes = ((USER_COUNT - upvotes) * DOWNVOTES_DISTRIBUTION.rng).round
    shuffled_user_ids = USER_IDS.shuffle
    upvoter_ids = shuffled_user_ids[0, upvotes]
    values += upvoter_ids.map { |id| columns.zip([1, id, pm.id]).to_h }
    downvoter_ids = shuffled_user_ids[upvotes, downvotes]
    values += downvoter_ids.map { |id| columns.zip([-1, id, pm.id]).to_h }
  end
  
  Upvote.insert_all values unless values.empty?
  
  puts "Completed in #{(Time.now - start_time).round 3} s"
end

create_upvotes Post
create_upvotes Comment
