require "test_helper"

class OrgCreatedNotificationJobTest < ActiveJob::TestCase
  FAKE_TOKEN = "my_user:tk_example_token_123456789098764"

  setup do
    @org = orgs(:one)
  end

  test "should send notification" do
    stub_notify = stub_notification_request
    assert_not_requested stub_notify

    with_env_var("NTFY_TOKEN", FAKE_TOKEN) do
      perform_enqueued_jobs do
        OrgCreatedNotificationJob.perform_later @org
      end
    end

    assert_requested stub_notify
  end

  private

  def stub_notification_request
    url = NotificationJob::notification_url(OrgCreatedNotificationJob::TOPIC)
    stub_request(:post, url).
      with(
        body: @org.email,
        headers: {
          Actions: OrgCreatedNotificationJob::actions(@org),
          Authorization: NotificationJob::authorization(FAKE_TOKEN),
          Title: NotificationJob::title(OrgCreatedNotificationJob::TOPIC),
        }
      )
  end
end
