include ActionView::Helpers::DateHelper

namespace :org do
  desc 'Simulate a fake org for any user'
  task :simulation => :environment do
    puts
    puts 'WARNING: USE THIS COMMAND CAREFULLY!'
    puts 'It has the power to add fake users, officers, comments, posts, etc. '
    puts 'to any user whose Org only has one member.'

    puts
    puts 'Paste the user_id of the user to simulate as the founder, or leave it'
    puts 'blank to default to the most recently created user'
    print '[<user_id>]: '
    user_id = STDIN.gets.chomp

    if user_id.blank?
      user = User.last
    else
      user = User.find_by id: user_id
    end

    unless user
      puts 'Error: no user found with that user_id'
      abort
    end

    unless user.org&.users.count == 1
      puts 'Error: user must be the only member of their Org'
      abort
    end

    puts
    puts 'Are you certain that this is the correct user?'
    puts user.pseudonym.indent(2)
    puts "- ID: #{user.id}".indent(2)
    puts "- Tenure: #{time_ago_in_words(user.created_at)}".indent(2)
    puts "- Current Org".indent(2)
    puts "- ID: #{user.org.id}".indent(4)
    puts
    puts "To confirm, type the user's pseudonym to continue:"
    print "[#{user.pseudonym.downcase}]: "
    abort unless STDIN.gets.chomp.downcase == user.pseudonym.downcase

    puts
    puts "Paste the user\'s base64-encoded group key below."
    puts 'To access your Org\'s base64-encoded group key:'
    puts '1. Start the app with ENABLE_DEVELOPER_SETTINGS=true'.indent(2)
    puts '2. Navigate to the Settings screen in the Org tab'.indent(2)
    puts '3. Under the "Developer" section, tap "Share Group Key"'.indent(2)
    print '[<group_key_base64>]: '
    group_key_base64 = STDIN.gets.chomp

    puts "Creating seeds..."
    start_time = Time.now

    $simulation = Simulation.new
    $simulation.run founder_id: user.id, group_key_base64: group_key_base64

    # The unusual code below is a holdover from when these seeds used to be
    # created using rails db:seeds task. It basically runs all seed scripts in
    # that directory in lexicographical order. For more info, see:
    # https://guides.rubyonrails.org/active_record_migrations.html#migrations-and-seed-data
    Dir[
      File.join Rails.root, 'lib', 'tasks', 'org', 'simulation', 'seeds', '*.rb'
    ].sort.each { |seed| load seed }

    puts "Created seeds. Completed in #{(Time.now - start_time).round 3} s"
  end

  # Alias rake org:sim to rake org:simulation
  task :sim => 'org:simulation'
end
