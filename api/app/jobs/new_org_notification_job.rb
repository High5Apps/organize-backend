class NewOrgNotificationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless Rails.env.production?

    HTTParty.post(
      Rails.application.credentials.dig(:notification_urls, :new_org),
      headers: {
        Title: 'New Org Created',
      }
    )
  end
end
