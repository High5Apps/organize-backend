class OrgCreatedNotificationJob < NotificationJob
  BODY_FORMAT = %(
Welcome to Organize!

I'm Julian, and I'm here to help you form your own union.

To help me know you're real, can you tell me a little bit about the issues at your workplace?

If you just want to try out the app ASAP, your verification code is: %{verification_code}, but please reply to this email when you get a chance.

And if you've got any questions for me, feel free to ask!

Thanks,
Julian Tigler
https://getorganize.app/blog/tips_for_starting_a_union
  ).strip
  TOPIC = "org_created"

  def perform(org)
    send_notification TOPIC,
      body: org.email,
      headers: {Actions: self.class.actions(org)}
  end

  def self.actions(org)
    email, verification_code = org.email, org.verification_code
    mail_to = "mailto:%{email}?subject=%{subject}&body=%{body}" % {
      body: ERB::Util.url_encode(BODY_FORMAT % {verification_code:}),
      email:,
      subject: ERB::Util.url_encode('Organize Verification'),
    }

    "view, Compose Email, #{mail_to}, clear=true"
  end
end
