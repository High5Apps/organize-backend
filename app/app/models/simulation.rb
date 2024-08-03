class Simulation
  attr_reader :started_at, :ended_at, :founder_id

  def initialize
    start = Time.now

    # https://www.researchgate.net/figure/Histogram-of-the-Firm-Size-Distribution-Note-Truncated-to-firms-with-1000-employees-or_fig1_228197633
    # https://www.wolframalpha.com/input?i=log+normal+distribution+mean+4.7+std+0.6
    us_company_size_distribution = Rubystats::LognormalDistribution.new(4.7, 0.6)
    size = us_company_size_distribution.rng.round
    @company = Company.new(size)

    finish = Time.now
    puts "Initialized company in #{(finish - start).round 3} s"
  end

  def run(founder_id:, group_key_base64:, days: 10)
    @founder_id = founder_id
    @group_key_base64 = group_key_base64
    @day = 0
    @connections = []
    @posts = []
    @members = Set[]

    founder = @company.most_passionate_employee
    founder.id = @founder_id
    @members.add founder

    @ended_at = Time.now
    days.times do
      day_start = @ended_at - (days - @day).days
      @started_at ||= day_start
      run_day day_start
      break if @members.count >= @company.size
    end
  end

  def to_seed_data
    {
      connections: @connections.map { |e1, e2, t| [e1.id, e2.id, t] },
      posts: @posts.map { |employee, timestamp| [employee.id, timestamp]},
      size: @company.size,
      user_ids: @members.map(&:id),
    }
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

  private

  def run_day(day_start)
    @day += 1
    puts
    puts "Day #{@day}"
    puts "-----------------"

    run_day_connections(day_start)
    run_day_posts(day_start)
  end

  def run_day_connections(day_start)
    second_offset = 0
    @members.to_a.each do |member|
      unasked_close_links = member.unasked_closely_linked_employee_set
      next if unasked_close_links.count == 0

      daily_enthusiasm = rand 0..5
      next if daily_enthusiasm == 0

      puts "Member #{member.index} will ask up to #{daily_enthusiasm} close links to join today"
      close_links_to_ask = unasked_close_links.to_a.sample(daily_enthusiasm)
      close_links_to_ask.each do |to_ask|
        member.asked_closely_linked_employee_set.add to_ask
        accepted = (rand < to_ask.probability_of_joining)
        result = accepted ? "Accepted" : "Rejected"
        already_member = @members.include? to_ask
        action = already_member ? 'connect' : 'join'
        puts ' '*2 + "Asking Employee #{to_ask.index} to #{action}... #{result}"

        next unless accepted

        second_offset += 1
        @members.add to_ask
        @connections.push [member, to_ask, day_start + second_offset.seconds]
      end
    end

    puts "Members: #{@members.count} of #{@company.size}"
  end

  def run_day_posts(day_start)
    any_posts_today = false

    @members.each do |member|
      # Using probability_of_joining as a score of enthusiasm, the probability
      # of posting grows linearly with enthusiasm from 1/20 to 1/10
      probability_of_posting = 0.05 + (0.05 * member.probability_of_joining)
      next unless rand < probability_of_posting

      # Add up to a single line break between between the previous simulation
      # section and this one, but only if there's at least one post today
      puts unless any_posts_today
      any_posts_today = true

      puts "Member #{member.index} created a post"
      @posts.push [member, day_start]
    end
  end
end
