class Simulation
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

  def run(days: 10)
    @day = 0
    @connections = []
    @members = Set[]
    @members.add @company.most_passionate_employee
    days.times do
      run_day
      break if @members.count >= @company.size
    end

    puts @connections.map { |sharer, scanner| [sharer.id, scanner.id] }.inspect
    puts @connections.count
  end

  private

  def run_day
    @day += 1
    puts
    puts "Day #{@day}"
    puts "-----------------"

    @members.to_a.each do |member|
      unasked_close_links = member.unasked_closely_linked_employee_set
      next if unasked_close_links.count == 0

      daily_enthusiasm = rand 0..5
      next if daily_enthusiasm == 0

      puts "Member #{member.id} will ask up to #{daily_enthusiasm} close links to join today"
      close_links_to_ask = unasked_close_links.to_a.sample(daily_enthusiasm)
      close_links_to_ask.each do |to_ask|
        member.asked_closely_linked_employee_set.add to_ask
        accepted = (rand < to_ask.probability_of_joining)
        result = accepted ? "Accepted" : "Rejected"
        already_member = @members.include? to_ask
        action = already_member ? 'connect' : 'join'
        puts ' '*2 + "Asking Employee #{to_ask.id} to #{action}... #{result}"

        next unless accepted
        @members.add to_ask
        @connections.push [member, to_ask]
      end
    end

    puts "Members: #{@members.count} of #{@company.size}"
  end
end
