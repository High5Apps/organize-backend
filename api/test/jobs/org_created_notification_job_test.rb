require "test_helper"

class OrgCreatedNotificationJobTest < ActiveJob::TestCase
  FAKE_TOKEN = "my_user:tk_example_token_123456789098764"

  setup do
    @org = orgs(:one)
  end

  test "should make a post request to NOTIFICATION_URL" do
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
    stub_request(:post, OrgCreatedNotificationJob::NOTIFICATION_URL).
      with(
        body: @org.email,
        headers: {
          Actions: OrgCreatedNotificationJob::actions(@org),
          Authorization: OrgCreatedNotificationJob::authorization(FAKE_TOKEN),
          Title: OrgCreatedNotificationJob::NOTIFICATION_TITLE,
        }
      )
  end
end
