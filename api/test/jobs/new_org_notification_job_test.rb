require "test_helper"

class NewOrgNotificationJobTest < ActiveJob::TestCase
  FAKE_NOTIFICATION_URL = 'https://example.com/12345'

  test "should no-op unless environment is production" do
    assert_not Rails.env.production?

    stub_notify = stub_notification_request
    assert_not_requested stub_notify

    perform_enqueued_jobs do
      NewOrgNotificationJob.perform_later
    end

    assert_not_requested stub_notify
  end

  test "should make a post request to credentials.notification_urls.new_org" do
    Rails.env = 'production'
    assert Rails.env.production?

    stub_notify = stub_notification_request
    assert_not_requested stub_notify

    notification_urls = { new_org: FAKE_NOTIFICATION_URL }
    with_rails_credentials(notification_urls:) do
      perform_enqueued_jobs do
        NewOrgNotificationJob.perform_later
      end
    end

    assert_requested stub_notify
  end

  private

  def stub_notification_request
    stub_request(:post, FAKE_NOTIFICATION_URL)
  end
end
