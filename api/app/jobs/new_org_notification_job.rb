class NewOrgNotificationJob < ApplicationJob
  queue_as :default

  NOTIFICATION_URL = "http://monitor-notify/org_created"
  NOTIFICATION_TITLE = "New Org Created"

  def perform(*args)
    HTTParty.post(
      NOTIFICATION_URL,
      headers: {
        Authorization: self.class.authorization(ENV.fetch("NTFY_TOKEN")),
        Title: NOTIFICATION_TITLE,
      }
    )
  end

  def self.authorization(token)
    "Bearer #{token.split(":")[1]}"
  end
end
