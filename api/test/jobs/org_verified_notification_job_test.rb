require "test_helper"

class OrgVerifiedNotificationJobTest < ActiveJob::TestCase
  FAKE_TOKEN = "my_user:tk_example_token_123456789098764"

  setup do
    @org = orgs(:one)
  end

  test "should send notification" do
    stub_notify = stub_notification_request
    assert_not_requested stub_notify

    with_env_var("NTFY_TOKEN", FAKE_TOKEN) do
      perform_enqueued_jobs do
        OrgVerifiedNotificationJob.perform_later @org
      end
    end

    assert_requested stub_notify
  end

  private

  def stub_notification_request
    url = NotificationJob::notification_url(OrgVerifiedNotificationJob::TOPIC)
    stub_request(:post, url).
      with(
        body: @org.email,
        headers: {
          Authorization: NotificationJob::authorization(FAKE_TOKEN),
          Title: NotificationJob::title(OrgVerifiedNotificationJob::TOPIC),
        }
      )
  end
end
