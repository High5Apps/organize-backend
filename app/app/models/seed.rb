class Seed
  # The Pareto distribution below is unbounded and can sometimes be more than
  # 1000. This cap helps to guard against those rare and unrealistic scenarios.
  BALLOT_DISTRIBUTION_MAX = 30

  BALLOTS_DISTRIBUTION = -> { [(1/rand).round, BALLOT_DISTRIBUTION_MAX].min }

  CANDIDACY_ANNOUNCEMENT_FRACTION = 0.8

  # These should add to 1.0
  CATEGORY_FRACTIONS = {
    general: 0.6,
    grievances: 0.25,
    demands: 0.15,
  }

  # https://www.wolframalpha.com/input?i=beta+distribution+%282%2C+20%29
  CHARACTERS_IN_BODY_DISTRIBUTION = Rubystats::BetaDistribution.new(2, 20)

  # https://www.wolframalpha.com/input?i=beta+distribution+%282%2C+50%29
  CHARACTERS_IN_COMMENT_DISTRIBUTION = Rubystats::BetaDistribution.new(2, 50)

  CHARACTERS_PER_PARAGRAPH_MIN = 20

  # This isn't statistically or mathematically correct, but it seems pretty close
  COMMENTS_PER_POST_APPROXIMATION = 2.5

  # The Pareto distribution below is unbounded and can sometimes be more than
  # 1000. This cap helps to guard against those rare and unrealistic scenarios.
  COMMENTS_PER_POST_MAX = 100

  # 1.161 is the required alpha for the 80/20 Pareto distribution. With it, 20%
  # of posts will receive 80% of comments. 1.161 approximately equals log4_5. See
  # https://en.wikipedia.org/wiki/Pareto_distribution#Relation_to_the_%22Pareto_principle%22
  COMMENTS_ON_POST_DISTRIBUTION = -> {
    [(1 / (rand**(1 / 1.161)) - 1).round, COMMENTS_PER_POST_MAX].min
  }

  # https://www.wolframalpha.com/input?i=beta+distribution+%281%2C+20%29
  DOWNVOTES_DISTRIBUTION = Rubystats::BetaDistribution.new(1, 20)

  # https://www.wolframalpha.com/input?i=beta+distribution+%281%2C+2%29
  ELAPSED_TIME_BETWEEN_COMMENTS_DISTRIBUTION = \
    Rubystats::BetaDistribution.new(1, 2)

  FLAGGED_DOWNVOTES_FRACTION = 0.03
  FLAGGED_VOTES_FRACTION = 0.01
  PARAGRAPH_COUNT_MAX = 10
  PARAGRAPH_WITH_URL_FRACTION = 0.05
  POSTS_WITHOUT_BODY_FRACTION = 0.5
  QUESTION_PREFIXES = {
    multiple_choice: 'Which of these should we ',
    yes_no: 'Should we ',
  }
  QUESTION_SUFFIX = '?'
  TITLE_CHARACTER_RANGE = 20..Post::MAX_TITLE_LENGTH

  # https://www.wolframalpha.com/input?i=beta+distribution+%282%2C+19%29
  UPVOTES_DISTRIBUTION = Rubystats::BetaDistribution.new(2, 19)

  VOTER_TURNOUT_DISTRIBUTION = Rubystats::NormalDistribution.new(0.7, 0.1)

  def initialize(simulation, group_key_base64)
    @simulation = simulation
    @group_key_base64 = group_key_base64
    @founder = User.find @simulation.founder_id
    @org = @founder.org
  end

  def create_random_seeds
    benchmark 'Created random seeds' do
      create_users
      update_org
      create_connections
      create_posts
      create_ballots
      create_elections office_state_map: random_office_state_map,
        should_create_elections_fraction: 0.9
      create_nominations acceptance_fraction: 0.6
      create_candidates
      create_candidacy_announcements
      create_votes
      create_terms acceptance_fraction: 0.9
      create_comments
      create_post_upvotes
      create_comment_upvotes
      create_post_flags
      create_comment_flags
      create_ballot_flags
      create_moderation_events
      update_users
    end
  end

  def create_screenshot_seeds
    create_users
    update_org
    create_connections
    create_elections office_state_map: {
      president: :term,
      treasurer: :voting,
      secretary: :nominations,
    }, should_create_elections_fraction: 1
    create_nominations acceptance_fraction: 1
    create_votes
    create_terms acceptance_fraction: 1

    # Adjust end dates to match the ideal screenshots
    # Note that with these adjustments, these ballots are no longer valid
    @org.ballots.president.first.update_attribute :voting_ends_at, 8.days.ago
    @org.ballots.treasurer.first
      .update_attribute :voting_ends_at, 3.5.days.from_now
    secretary = @org.ballots.secretary.first
    secretary.nominations_end_at = 1.5.days.from_now
    secretary.voting_ends_at = secretary.nominations_end_at + 1.day
    secretary.save! validate: false
  end

  private

  def benchmark(message, &block)
    elapsed_time_ms = Benchmark.ms(&block)
    puts "#{message} (#{elapsed_time_ms.round}ms)"
  end

  def create_users
    user_ids = @simulation.to_seed_data[:user_ids]

    benchmark "Created #{user_ids.count} users" do
      travel_to @simulation.started_at do
        user_ids.each do |user_id|
          if user_id == @founder.id
            # Update founder timestamps to align with simulation timestamps.
            # Otherwise the founder would have a shorter tenure than other
            # members.
            @founder.update! created_at: @simulation.started_at,
              joined_at: @simulation.started_at

            # Don't attempt to recreate the pre-existing founder
            next
          end

          key_pair = OpenSSL::PKey::EC.generate "prime256v1"
          User.create! id: user_id, public_key_bytes: key_pair.public_to_der
        end
      end
    end
  end

  def random_company_name
    companies_string = "Walmart,Amazon.com,Costco Wholesale,The Home Depot,The Kroger Co.,Walgreens Boots Alliance,Target,CVS Health Corporation,Lowe's Companies,Albertsons Companies,Apple Stores / iTunes,Royal Ahold Delhaize USA,Publix Super Markets,Best Buy,TJX Companies,Aldi,Dollar General,H.E. Butt Grocery,Dollar Tree,Ace Hardware,Macy's,7-Eleven,AT&T Wireless,Meijer,Verizon Wireless,Ross Stores,Kohl's,Wakefern / ShopRite,Rite Aid,BJ's Wholesale Club,Dell Technologies,Gap,Nordstrom,Menards,O’Reilly Auto Parts,Tractor Supply Co.,AutoZone,Dick's Sporting Goods,Hy Vee,Wayfair,Health Mart Systems,Wegmans Food Market,Qurate Retail,Giant Eagle,Alimentation Couche-Tard,Sherwin-Williams,Burlington,J.C. Penney Company,WinCo Foods,Chewy.com,Good Neighbor Pharmacy,Ulta Beauty,Williams-Sonoma,Army and Air Force Exchange Service,PetSmart,Bass Pro,Bath & Body Works,Southeastern Grocers,AVB Brandsource,Academy Sports,Staples,Dillard's,Hobby Lobby Stores,Bed Bath & Beyond,Big Lots,Signet Jewelers,Foot Locker,Sprouts Farmers Market,Sephora (LVMH),Ikea North America Services,Discount Tire,Camping World,Petco,True Value Co.,Office Depot,Victoria's Secret,Michaels Stores,Piggly Wiggly,Stater Bros Holdings,My Demoulas,Advance Auto,Harbor Freight Tools,Exxon Mobil Corporation,Hudson's Bay,Save-A-Lot,American Eagle Outfitters,Total Wine & More,Defense Commissary Agency,Ingles,Weis Markets,Casey's General Store,Tapestry,Smart & Final,Lululemon,Shell Oil Company,Golub,Save Mart,RH,Urban Outfitters,Barnes & Noble"
    companies_string.split(',').sample
  end

  def encrypt(message)
    return nil if message.nil?

    unless @cipher
      group_key = Base64.decode64 @group_key_base64
      @cipher = ActiveRecord::Encryption::Cipher::Aes256Gcm.new group_key
    end

    em = @cipher.encrypt message
    encrypted_message = EncryptedMessage.new

    # Using strict_encode64 because regular encode64 adds unwanted new lines
    encrypted_message.ciphertext = Base64.strict_encode64(em.payload)
    encrypted_message.nonce = Base64.strict_encode64(em.headers.iv)
    encrypted_message.auth_tag = Base64.strict_encode64(em.headers.auth_tag)

    encrypted_message.attributes
  end

  def update_org
    benchmark "Updated Org" do
      random_local_number = rand 1000..9999
      random_store_number = rand 100..999

      travel_to @simulation.started_at do
        attributes = {
          created_at: @simulation.started_at,
          encrypted_name: encrypt("Local #{random_local_number}"),
          encrypted_member_definition: encrypt("An employee of #{random_company_name} at store ##{random_store_number}"),
        }
        @org.update! attributes
        @founder.reload
      end
    end
  end

  def create_connections
    connection_data = @simulation.to_seed_data[:connections]

    benchmark "Created #{connection_data.count} connections" do
      connection_data.each do |sharer_id, scanner_id, timestamp|
        travel_to timestamp do
          Connection.create sharer_id:, scanner_id:
        end
      end
    end
  end

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

  def example_url
    protocol = ['', 'http://', 'https://'].sample
    "#{protocol}example.com/#{rand(0...1e9).floor}"
  end

  def hipster_ipsum_post_body
    return if rand < POSTS_WITHOUT_BODY_FRACTION

    approximate_body_length = \
      Post::MAX_BODY_LENGTH * CHARACTERS_IN_BODY_DISTRIBUTION.rng
    paragraph_count = rand 1..PARAGRAPH_COUNT_MAX
    max_characters_per_paragraph = approximate_body_length / paragraph_count

    paragraphs = (0...paragraph_count).map do
      characters = \
        [CHARACTERS_PER_PARAGRAPH_MIN, max_characters_per_paragraph].max
      p = Faker::Hipster.paragraph_by_chars(characters:)

      # Remove the final sentence to ensure no partial words
      p.delete_suffix! '.' # Remove the final period
      p = p[0..p.rindex('.')] # Remove the last sentence

      p += " #{example_url}" if rand < PARAGRAPH_WITH_URL_FRACTION
      p
    end

    paragraphs.join "\n\n"
  end

  def create_posts
    post_data = @simulation.to_seed_data[:posts]

    benchmark "Created #{post_data.count} posts" do
      post_data.each do |user_id, day_start|
        created_at = random_time_during_day day_start

        travel_to created_at do
          User.find(user_id).posts.create! category: random_category.to_s,
            encrypted_title: encrypt(hipster_ipsum_post_title),
            encrypted_body: encrypt(hipster_ipsum_post_body),
            org: @org
        end
      end
    end
  end

  def hipster_ipsum_ballot_question(prefix, suffix)
    question_range_max = \
      Ballot::MAX_QUESTION_LENGTH - prefix.length - suffix.length
    question_length = rand 20..question_range_max
    question = Faker::Hipster.paragraph_by_chars(characters: question_length)
      .delete('.') # Remove all periods
      .downcase
      .split[...-1] # Remove last word to ensure no partial words
      .join ' '
    "#{prefix}#{question}#{suffix}"
  end

  def create_fake_ballot(category:, isActive:)
    created_at = Faker::Time.between from: @simulation.started_at,
      to: @simulation.ended_at

    voting_ends_at = if isActive
      Faker::Time.between from: @simulation.ended_at,
        to: @simulation.ended_at + 2.weeks
    else
      Faker::Time.between from: created_at, to: @simulation.ended_at
    end

    encrypted_question = encrypt hipster_ipsum_ballot_question(
      QUESTION_PREFIXES[category], QUESTION_SUFFIX)

    # Pick a random member who had joined by that time to be the creator
    creator = @org.users.joined_at_or_before(created_at).sample

    travel_to created_at do
      creator.ballots.create! category:, encrypted_question:, voting_ends_at:
    end
  end

  def create_ballots
    inactive_yes_no_ballot_count = BALLOTS_DISTRIBUTION.call
    active_yes_no_ballot_count = BALLOTS_DISTRIBUTION.call
    inactive_multiple_choice_ballot_count = BALLOTS_DISTRIBUTION.call
    active_multiple_choice_ballot_count = BALLOTS_DISTRIBUTION.call
    ballot_count = [
      inactive_yes_no_ballot_count,
      active_yes_no_ballot_count,
      inactive_multiple_choice_ballot_count,
      active_multiple_choice_ballot_count,
    ].sum

    benchmark "Created #{ballot_count} ballots" do
      inactive_yes_no_ballot_count.times do
        create_fake_ballot category: :yes_no, isActive: false
      end

      active_yes_no_ballot_count.times do
        create_fake_ballot category: :yes_no, isActive: true
      end

      inactive_multiple_choice_ballot_count.times do
        create_fake_ballot category: :multiple_choice, isActive: false
      end

      active_multiple_choice_ballot_count.times do
        create_fake_ballot category: :multiple_choice, isActive: true
      end
    end
  end

  def create_elections(office_state_map:, should_create_elections_fraction:)
    unless rand < should_create_elections_fraction
      puts "Skipping election creation"
      return
    end

    non_none_office_states = office_state_map.reject { |k, v| v == :none }
    benchmark "Created #{non_none_office_states.count} elections" do
      user_count = @org.users.count
      users_per_steward = rand 15..25
      steward_count = (user_count / users_per_steward)

      office_state_map.each do |office, state|
        next if state == :none
        next if (office == :steward) && steward_count == 0

        office_title = office.to_s.titleize
        encrypted_question = encrypt("Who should we elect #{office_title}?")

        max_candidate_ids_per_vote = (office == :steward) ? steward_count : 1

        voting_ends_at = @simulation.ended_at + {
          term: -2.days,
          term_acceptance: -1.day,
          voting: 1.day,
          nominations: 2.days,
        }[state]
        term_starts_at = voting_ends_at + 2.days
        term_ends_at = term_starts_at + 1.year
        nominations_end_at = voting_ends_at - 1.day
        created_at = nominations_end_at - 2.days

        travel_to created_at do
          @founder.ballots.create!({
            category: 'election',
            encrypted_question:,
            max_candidate_ids_per_vote:,
            nominations_end_at:,
            office:,
            term_ends_at:,
            term_starts_at:,
            voting_ends_at:,
          })
        end
      end
    end
  end

  def random_office_state_map
    # Must be in progress order. :term appears twice to increase its
    # likelihood
    states = [
      :none, :nominations, :voting, :term_acceptance, :term, :term,
    ]
    state_map = {}
    Office::TYPE_SYMBOLS.each do |office|
      # This relies on Office::TYPE_SYMBOLS being in rank order
      state = case office
      when :founder
        # Already automatically created during first Org creation
        :none
      when :president, :treasurer
        states.sample
      when :vice_president, :secretary
        # Don't allow VP or secretary state to be ahead of president state
        president_state_index = states.rindex(state_map[:president])
        states[..president_state_index].sample
      when :steward
        states.sample
      when :trustee
        # Don't allow trustee state to be ahead of treasurer state
        treasurer_state_index = states.rindex(state_map[:treasurer])
        states[..treasurer_state_index].sample
      else
        raise "Unhandled office: #{office}"
      end

      state_map[office] = state
    end

    state_map
  end

  def create_nominations(acceptance_fraction:)
    users = @org.users
    elections = @org.ballots.election

    benchmark "Created about #{5 * elections.count} nominations" do
      elections.each do |election|
        nominations_end = election.nominations_end_at
        joined_users = users.joined_at_or_before(nominations_end)
        max_nomination_count = rand 1..10
        nominators_and_nominees = joined_users.ids.sample 2 * max_nomination_count
        nomination_count = nominators_and_nominees.count / 2

        nomination_count.times do
          # nominations_end could be after the simulation ends, so need to
          # clamp, because don't want to simulate user actions after the
          # simulation ends
          nomination_actions_cutoff = \
            [nominations_end, @simulation.ended_at].min

          nomination_created_at = \
            rand (election.created_at)...nomination_actions_cutoff
          nominator_id, nominee_id = nominators_and_nominees.shift 2
          nomination = nil
          travel_to nomination_created_at do
            nomination = election.nominations
              .create!(nominator_id:, nominee_id:)
          end

          if rand < acceptance_fraction
            accepted = true
          elsif rand < 0.5
            # Decline the nomination half of the time it's not accepted
            accepted = false
          else
            # Ignore the nomination half of the time it's not accepted
            next
          end

          accepted_or_declined_at = \
            rand nomination_created_at...nomination_actions_cutoff
          travel_to accepted_or_declined_at do
            nomination.update!(accepted:)
          end
        end
      end
    end
  end

  def hipster_ipsum_candidate_title
    title_length = rand 3..Candidate::MAX_TITLE_LENGTH
    Faker::Hipster.paragraph_by_chars(characters: title_length)
      .delete('.') # Remove all periods
  end

  def create_candidates
    ballots = @org.ballots
    yes_no_ballots = ballots.yes_no
    multiple_choice_ballots = ballots.multiple_choice
    approximate_candidate_count = \
      2 * yes_no_ballots.count + 6 * multiple_choice_ballots.count

    benchmark "Created about #{approximate_candidate_count} candidates" do
      yes_no_ballots.all.each do |ballot|
        travel_to ballot.created_at do
          ballot.candidates.create! encrypted_title: encrypt('Yes')
          ballot.candidates.create! encrypted_title: encrypt('No')
        end
      end

      multiple_choice_ballots.all.each do |ballot|
        travel_to ballot.created_at do
          candidate_count = rand 2..10
          selection_count = rand 1..candidate_count

          candidate_count.times do
            title = hipster_ipsum_candidate_title
            ballot.candidates.create! encrypted_title: encrypt(title)
            ballot.update(max_candidate_ids_per_vote: selection_count)
          end
        end
      end
    end
  end

  def create_candidacy_announcements
    election_candidate_count = @org.ballots.election.joins(:candidates).count
    expected_post_count = \
      (CANDIDACY_ANNOUNCEMENT_FRACTION * election_candidate_count).round

    benchmark "Created about #{expected_post_count} candidacy announcements" do
      elections = @org.ballots.election.includes(candidates: [:user])
      elections.each do |election|
        office_title = election.office.titleize

        election.candidates.each do |candidate|
          next unless rand < CANDIDACY_ANNOUNCEMENT_FRACTION

          pseudonym = candidate.user.pseudonym
          title = "#{pseudonym} is running for #{office_title}"

          created_at = candidate.created_at + 1.minute
          travel_to created_at do
            candidate.create_post! category: :general,
              encrypted_title: encrypt(title),
              encrypted_body: encrypt(hipster_ipsum_post_body),
              org: @org,
              user: candidate.user
          end
        end
      end
    end
  end

  def create_votes
    users = @org.users
    ballots = @org.ballots

    benchmark "Created votes on #{ballots.count} ballots" do
      values = []

      ballots.all.each do |ballot|
        candidate_ids = ballot.candidates.ids
        next if candidate_ids.blank?

        next if ballot.election? &&
          (ballot.nominations_end_at > @simulation.ended_at)

        max_candidate_ids_per_vote = ballot.max_candidate_ids_per_vote
        selection_map = {}

        potential_voter_ids = users.joined_at_or_before(ballot.created_at).ids
        voter_turnout_fraction = VOTER_TURNOUT_DISTRIBUTION.rng.clamp(0, 1)
        voter_turnout_count = \
          (potential_voter_ids.count * voter_turnout_fraction).floor
        voter_ids = potential_voter_ids.sample(voter_turnout_count)
        current_voter_ids = voter_ids

        max_candidate_ids_per_vote.times do
          # Randomly place (n-1) dividers to split the spectrum into n sections
          # -------|----|---|-
          position_distribution = Rubystats::UniformDistribution.new 0,
            current_voter_ids.count
          spectrum_dividers = (1...candidate_ids.count)
            .map { position_distribution.rng.floor }
            .sort
          candidate_vote_counts = \
            [0, *spectrum_dividers, current_voter_ids.count]
              .each_cons(2)
              .map { |a, b| b - a }

          current_candidate_index = 0
          current_candidate_vote_count = 0
          current_voter_ids.each_with_index do |voter_id, i|
            unless current_candidate_vote_count < candidate_vote_counts[current_candidate_index]
              current_candidate_vote_count = 0
              current_candidate_index += 1
            end

            unless selection_map.key? voter_id
              selection_map[voter_id] = []
            end

            selection_map[voter_id].push candidate_ids[current_candidate_index]
            current_candidate_vote_count += 1
          end

          # When multiple votes are allowed, 90% of the previous voters create
          # another vote
          next_round_voter_count = (0.9 * current_voter_ids.count).floor
          current_voter_ids = current_voter_ids.sample(next_round_voter_count)
        end

        selection_map.each do |voter_id, selected_candidate_ids|
          values.push({
            ballot_id: ballot.id,
            candidate_ids: selected_candidate_ids.uniq,
            created_at: ballot.created_at + 1.second,
            updated_at: ballot.created_at + 1.second,
            user_id: voter_id,
          })
        end
      end

      Vote.insert_all values unless values.empty?
    end
  end

  def create_terms(acceptance_fraction:)
    elections_with_results = \
      @org.ballots.election.inactive_at @simulation.ended_at

    benchmark "Created about #{elections_with_results.count} terms" do
      elections_with_results.each do |election|
        election.winners.each do |winner|
          candidate = Candidate.find winner[:candidate_id]
          accepted = rand < acceptance_fraction
          next if !accepted && rand < 0.5 # Ignore 50% when it's unaccepted
          ballot = candidate.ballot
          travel_to ballot.term_starts_at - 1.second do
            ballot.terms.create!({
              accepted: accepted,
              ends_at: ballot.term_ends_at,
              office: ballot.office,
              starts_at: ballot.term_starts_at,
              user: candidate.user,
            })
          end
        end
      end
    end
  end

  def hipster_ipsum_comment_body
    approximate_body_length = \
      Comment::MAX_BODY_LENGTH * CHARACTERS_IN_COMMENT_DISTRIBUTION.rng
    paragraph_count = rand 1..3
    max_characters_per_paragraph = approximate_body_length / paragraph_count

    paragraphs = (0...paragraph_count).map do
      characters = \
        [CHARACTERS_PER_PARAGRAPH_MIN, max_characters_per_paragraph].max
      p = Faker::Hipster.paragraph_by_chars(characters:)

      # Remove the final sentence to ensure no partial words
      p.delete_suffix! '.' # Remove the final period
      p = p[0..p.rindex('.')] # Remove the last sentence

      p += " #{example_url}" if rand < PARAGRAPH_WITH_URL_FRACTION
      p
    end

    paragraphs.join "\n\n"
  end

  def create_comments
    users = @org.users
    posts = @org.posts
    comment_count_estimate = posts.count * COMMENTS_PER_POST_APPROXIMATION

    benchmark "Created roughly #{comment_count_estimate.round} comments" do
      posts.order(:created_at).each do |post|
        comment_count = COMMENTS_ON_POST_DISTRIBUTION.call
        next unless comment_count > 0

        available_timespan = @simulation.ended_at - post.created_at
        max_average_time_between_comments = available_timespan / comment_count
        current_time = post.created_at

        potential_parent_comments = []

        comment_count.times do
          # Pick a random amount of time to have elappsed since the last comment
          time_delta = max_average_time_between_comments *
            ELAPSED_TIME_BETWEEN_COMMENTS_DISTRIBUTION.rng
          comment_time = current_time + time_delta

          # Pick a random member who had joined by that time to be the commenter
          commenter = users.joined_at_or_before(comment_time).sample
          next unless commenter

          if rand < 0.8 && !potential_parent_comments.empty?
            parent = potential_parent_comments.sample
            next if parent.depth + 1 >= Comment::MAX_COMMENT_DEPTH
          end

          travel_to comment_time do
            comment = post.comments.create!(user: commenter,
              encrypted_body: encrypt(hipster_ipsum_comment_body),
              parent:)
            potential_parent_comments.push(comment)
          end
        end
      end
    end
  end

  def create_upvotes(parent_relation, user_ids)
    user_count = user_ids.count

    parent_relation_count = parent_relation.count
    expected_upvote_count = \
      (parent_relation_count * user_count * UPVOTES_DISTRIBUTION.mean).round
    expected_downvote_count = \
      (parent_relation_count * user_count * DOWNVOTES_DISTRIBUTION.mean).round
    parent_model = parent_relation.klass
    type = parent_model.to_s.downcase

    benchmark "Created roughly #{expected_upvote_count} #{type} upvotes and #{expected_downvote_count} #{type} downvotes" do
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
    end
  end

  def create_post_upvotes
    user_ids = @org.users.ids
    create_upvotes @org.posts, user_ids
  end

  def create_comment_upvotes
    user_ids = @org.users.ids
    create_upvotes Comment.where(post_id: @org.posts), user_ids
  end

  def create_flags(relation, flaggable_name, flagged_fraction)
    expected_flag_count = (relation.count * flagged_fraction).round

    benchmark "Created roughly #{expected_flag_count} flags on #{flaggable_name.pluralize}" do
      values = []

      relation.find_each do |flaggable|
        next unless rand < flagged_fraction

        created_at = flaggable.created_at + 3.seconds

        # Pick a random member who had joined by that time to be the
        # flag_creator
        flag_creator = @org.users.joined_at_or_before(created_at).sample

        values.push({
          flaggable_id: flaggable[flaggable_name.foreign_key] || flaggable.id,
          flaggable_type: flaggable_name,
          user_id: flag_creator.id,
          created_at: created_at,
          updated_at: created_at,
        })
      end

      Flag.insert_all values unless values.empty?
    end
  end

  def create_post_flags
    downvotes = @org.upvotes.where(value: -1)

    posts_without_candidacy_announcements = downvotes.joins(:post)
      .where(post: { candidate_id: nil })
    create_flags posts_without_candidacy_announcements,
      'Post', FLAGGED_DOWNVOTES_FRACTION
  end

  def create_comment_flags
    downvotes = @org.upvotes.where(value: -1)

    comments = downvotes.joins(:comment)
    create_flags comments, 'Comment', FLAGGED_DOWNVOTES_FRACTION
  end

  def create_ballot_flags
    non_election_votes = @org.ballots.not_election.joins(:votes)
    create_flags non_election_votes, 'Ballot', FLAGGED_VOTES_FRACTION
  end

  def create_moderation_events
    flaggable_type_counts = @org.flags.group(:flaggable_type).count
    flaggable_moderation_event_count = 2 * flaggable_type_counts.keys.count

    max_users_to_block = [@org.users.count, 4].min
    blocked_user_count = rand 0..max_users_to_block

    moderation_event_count = flaggable_moderation_event_count +
      blocked_user_count

    benchmark "Created about #{moderation_event_count} ModerationEvents" do
      flaggable_type_counts.keys.each do |flaggable_type|
        ordered_by_flag_count = @org.flags
          .where(flaggable_type: flaggable_type)
          .group(:flaggable_id)
          .select(:flaggable_id, 'COUNT(*) AS flag_count')
          .order(:flag_count, :flaggable_id)

        # Find a ballot with the min flag count and allow it
        flaggable_id_to_allow = ordered_by_flag_count.first.flaggable_id
        @founder.created_moderation_events.create!({
          action: 'allow',
          moderatable_id: flaggable_id_to_allow,
          moderatable_type: flaggable_type,
        })

        # Find a random ballot with the max flag count to block
        flaggable_id_to_block = ordered_by_flag_count.last.flaggable_id

        # If the flaggable to block is the one allowed above, must undo_allow
        # first
        if flaggable_id_to_block == flaggable_id_to_allow
          @founder.created_moderation_events.create!({
            action: 'undo_allow',
            moderatable_id: flaggable_id_to_block,
            moderatable_type: flaggable_type,
          })
        end

        # Block the flaggable
        @founder.created_moderation_events.create!({
          action: 'block',
          moderatable_id: flaggable_id_to_block,
          moderatable_type: flaggable_type,
        })
      end

      # Pick a few random users to block
      @org.users.ids.sample(blocked_user_count).each do |user_id|
        # Attempt to block each user. Note this could fail if the user is an
        # officer or other protected member.
        @founder.created_moderation_events.create({
          action: 'block',
          moderatable_id: user_id,
          moderatable_type: 'User',
        })
      end
    end
  end

  def update_users
    benchmark "Updated users" do
      # Pick up to 2 unblocked non-founder users with comments or posts to leave
      # the Org
      unblocked_non_founders = @org.users.omit_blocked.where.not id: @founder.id
      users_to_leave_org = [
        unblocked_non_founders.where.associated(:posts).to_a.sample,
        unblocked_non_founders.where.associated(:comments).to_a.sample,
      ].compact
      users_to_leave_org.each { |user| user.leave_org }
    end
  end
end
