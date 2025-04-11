require "test_helper"

class V1::WorkGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users :one
    setup_test_key @user
    @authorized_headers = authorized_headers @user, Authenticatable::SCOPE_ALL

    @work_group = work_groups :one
    @other_work_group = work_groups :two
    @update_params = { work_group: @other_work_group.as_json }
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

  test 'should update with valid params' do
    assert_changes -> { @work_group.reload.encrypted_department.attributes },
        from: @work_group.encrypted_department.attributes,
        to: @other_work_group.encrypted_department.attributes do
      assert_changes -> { @work_group.reload.encrypted_job_title.attributes },
          from: @work_group.encrypted_job_title.attributes,
          to: @other_work_group.encrypted_job_title.attributes do
        assert_changes -> { @work_group.reload.encrypted_shift.attributes },
            from: @work_group.encrypted_shift.attributes,
            to: @other_work_group.encrypted_shift.attributes do
          patch v1_work_group_url(@work_group),
            headers: @authorized_headers,
            params: @update_params
        end
      end
    end

    assert_response :ok
    assert_empty response.body
  end

  test 'should not update with invalid authorization' do
    assert_no_changes -> { @work_group.reload } do
      patch v1_work_group_url(@work_group),
        headers: authorized_headers(@user,
          Authenticatable::SCOPE_ALL,
          expiration: 1.second.ago),
        params: @update_params
      assert_response :unauthorized
    end
  end

  test 'should not update with invalid params' do
    assert_no_changes -> { @work_group.reload } do
      patch v1_work_group_url(@work_group),
        headers: @authorized_headers,
        params: { work_group: { encrypted_job_title: { c: 'invalid' } } }
      assert_response :unprocessable_entity
    end
  end

  test 'should not update work_group in another org' do
    assert_not_equal @user.org, @other_work_group.org
    patch v1_work_group_url(@other_work_group),
      headers: @authorized_headers,
      params: @update_params
    assert_response :not_found
  end

  test 'should not update without permission' do
    user = users :three
    setup_test_key(user)
    assert_not user.can? :edit_work_groups

    patch v1_work_group_url(@work_group),
      headers: authorized_headers(user, Authenticatable::SCOPE_ALL),
      params: @update_params
    assert_response :forbidden
  end

  private

  def get_work_group_ids_from_response
    response.parsed_body => work_groups: work_group_jsons
    work_group_jsons.map { |w| w[:id] }
  end
end
