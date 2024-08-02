org = User.find($simulation.founder_id).org

# Pick up to 2 users with comments or posts to leave the Org
users_to_leave_org = [
  org.users.omit_blocked.where.associated(:posts).to_a.sample,
  org.users.omit_blocked.where.associated(:comments).to_a.sample,
].compact

users_to_leave_org.each { |user| user.leave_org }
