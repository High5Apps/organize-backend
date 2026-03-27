class NotificationJob < ApplicationJob
  queue_as :default

  def send_notification(topic, body: nil, headers: {})
    HTTParty.post self.class.notification_url(topic),
      body:,
      headers: headers.merge(
        Authorization: self.class.authorization(ENV.fetch("NTFY_TOKEN")),
        Title: self.class.title(topic),
      )
  end

  def self.authorization(token)
    "Bearer #{token.split(":")[1]}"
  end

  def self.notification_url(topic)
    "http://monitor-notify/#{topic}"
  end

  def self.title(topic)
    topic.titleize
  end
end
