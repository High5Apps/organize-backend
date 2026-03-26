require "test_helper"

class NewOrgNotificationJobTest < ActiveJob::TestCase
  FAKE_TOKEN = "my_user:tk_example_token_123456789098764"

  test "should make a post request to NOTIFICATION_URL" do
    stub_notify = stub_notification_request
    assert_not_requested stub_notify

    with_env_var("NTFY_TOKEN", FAKE_TOKEN) do
      perform_enqueued_jobs do
        NewOrgNotificationJob.perform_later
      end
    end

    assert_requested stub_notify
  end

  private

  def stub_notification_request
    stub_request(:post, NewOrgNotificationJob::NOTIFICATION_URL).
      with(
        headers: {
          Authorization: NewOrgNotificationJob::authorization(FAKE_TOKEN),
          Title: NewOrgNotificationJob::NOTIFICATION_TITLE,
        }
      )
  end
end
