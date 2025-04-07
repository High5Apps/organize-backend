require "test_helper"

class V1::WorkGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users :one
    setup_test_key @user
    @authorized_headers = authorized_headers @user, Authenticatable::SCOPE_ALL
  end

  test 'should index' do
    get v1_work_groups_url, headers: @authorized_headers
    assert_response :ok

    response.parsed_body => work_groups: [first_work_group, *]
    assert_pattern do
      first_work_group => {
        encrypted_department: { c: String, n: String, t: String },
        encrypted_job_title: { c: String, n: String, t: String },
        encrypted_shift: { c: String, n: String, t: String },
        id: String,
        member_count: Integer,
        **nil
      }
    end
  end

  test 'should not index with invalid authorization' do
    get v1_work_groups_url,
      headers: authorized_headers(@user,
        Authenticatable::SCOPE_ALL,
        expiration: 1.second.ago)
    assert_response :unauthorized
  end

  test 'index should only include work_groups from requester Org' do
    get v1_work_groups_url, headers: @authorized_headers
    work_group_ids = get_work_group_ids_from_response
    assert_not_empty work_group_ids
    work_groups = WorkGroup.find(work_group_ids)
    assert_not_equal work_groups.count, WorkGroup.count
    work_groups.each do |work_group|
      assert_equal @user.org, work_group.org
    end
  end

  test 'index member_counts should be correct' do
    get v1_work_groups_url, headers: @authorized_headers
    response.parsed_body => work_groups:
    assert_not_empty work_groups
    work_groups.each do |work_group|
      assert_equal WorkGroup.find(work_group[:id]).union_cards.count,
        work_group[:member_count]
    end
  end

  private

  def get_work_group_ids_from_response
    response.parsed_body => work_groups: work_group_jsons
    work_group_jsons.map { |w| w[:id] }
  end
end
