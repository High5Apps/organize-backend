class OrgVerifiedNotificationJob < NotificationJob

  TOPIC = "org_verified"

  def perform(org)
    send_notification TOPIC, body: org.email
  end
end
