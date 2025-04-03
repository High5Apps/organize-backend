require "test_helper"

class WorkGroupTest < ActiveSupport::TestCase
  setup do
    @work_group = work_groups :one
  end

  test 'should be valid' do
    assert @work_group.valid?
  end

  test 'creator should be present' do
    @work_group.creator = nil
    assert @work_group.invalid?
  end

  test 'encrypted_department should be optional' do
    @work_group.encrypted_department = nil
    assert @work_group.valid?
  end

  test 'encrypted_department error messages should not include "Encrypted"' do
    @work_group.encrypted_department.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_DEPARTMENT_LENGTH))
    @work_group.valid?
    assert_not @work_group.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_department should be no longer than MAX_DEPARTMENT_LENGTH' do
    @work_group.encrypted_department.ciphertext = \
      Base64.strict_encode64('a' * WorkGroup::MAX_DEPARTMENT_LENGTH)
    assert @work_group.valid?

    @work_group.encrypted_department.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_DEPARTMENT_LENGTH))
    assert @work_group.invalid?
  end

  test 'encrypted_job_title should be present' do
    @work_group.encrypted_job_title = nil
    assert @work_group.invalid?
  end

  test 'encrypted_job_title error messages should not include "Encrypted"' do
    @work_group.encrypted_job_title.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_JOB_TITLE_LENGTH))
    @work_group.valid?
    assert_not @work_group.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_job_title should be no longer than MAX_JOB_TITLE_LENGTH' do
    @work_group.encrypted_job_title.ciphertext = \
      Base64.strict_encode64('a' * WorkGroup::MAX_JOB_TITLE_LENGTH)
    assert @work_group.valid?

    @work_group.encrypted_job_title.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_JOB_TITLE_LENGTH))
    assert @work_group.invalid?
  end

  test 'encrypted_shift should be present' do
    @work_group.encrypted_shift = nil
    assert @work_group.invalid?
  end

  test 'encrypted_shift error messages should not include "Encrypted"' do
    @work_group.encrypted_shift.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_SHIFT_LENGTH))
    @work_group.valid?
    assert_not @work_group.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_shift should be no longer than MAX_SHIFT_LENGTH' do
    @work_group.encrypted_shift.ciphertext = \
      Base64.strict_encode64('a' * WorkGroup::MAX_SHIFT_LENGTH)
    assert @work_group.valid?

    @work_group.encrypted_shift.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_SHIFT_LENGTH))
    assert @work_group.invalid?
  end
end
