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
    puts "- Name: #{user.org.name}".indent(4)
    puts "- ID: #{user.org.id}".indent(4)
    puts
    puts "To confirm, type the user's pseudonym to continue:"
    print "[#{user.pseudonym.downcase}]: "
    abort unless STDIN.gets.chomp.downcase == user.pseudonym.downcase

    puts "Creating seeds..."
    start_time = Time.now

    $simulation = Simulation.new
    $simulation.run founder_id: user.id

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

  desc "Switch any user to be in any Org"
  task :switch => :environment do |task_name|
    puts
    puts 'WARNING: USE THIS COMMAND CAREFULLY!'
    puts 'It has the power to switch any user from one Org to another.'
    puts "It's like leaving the current Org and scanning the new Org's"
    puts "founder's code."

    puts
    puts 'Paste the user_id of the user that should switch Orgs, or leave it'
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

    puts
    puts 'Are you certain that this is the correct user?'
    puts user.pseudonym.indent(2)
    puts "- ID: #{user.id}".indent(2)
    puts "- Tenure: #{time_ago_in_words(user.created_at)}".indent(2)
    puts "- Current Org".indent(2)
    puts "- Name: #{user.org.name}".indent(4)
    puts "- ID: #{user.org.id}".indent(4)
    puts
    puts "To confirm, type the user's pseudonym to continue:"
    print "[#{user.pseudonym.downcase}]: "
    abort unless STDIN.gets.chomp.downcase == user.pseudonym.downcase

    puts
    puts 'Paste the org_id of the Org that the user should switch to, or leave it'
    puts 'blank to default to the oldest Org'
    print '[<org_id>]: '
    org_id = STDIN.gets.chomp

    if org_id.blank?
      org = Org.first
    else
      org = Org.find_by id: org_id
    end

    unless org
      puts 'Error: no Org found with that org_id'
      abort
    end

    puts
    puts 'Are you certain that this is the correct new Org?'
    puts org.name.indent(2)
    puts "- ID: #{org.id}".indent(2)
    puts "- Created: #{time_ago_in_words(org.created_at)} ago".indent(2)
    puts "- Members: #{org.users.count}".indent(2)
    puts
    puts "To confirm, type the Org's name to continue:"
    print "[#{org.name.downcase}]: "
    abort unless STDIN.gets.chomp.downcase == org.name.downcase

    puts 'Switching...'
    User.transaction do
      user.update!(org_id: nil)
      user.terms.destroy_all
      user.scanned_connections.destroy_all
      user.shared_connections.destroy_all

      if org.users.exists?
        user.scanned_connections.create!(sharer: org.users.first)
      else
        user.update!(org_id: org.id)
      end
    end
  end
end
