require "test_helper"

class UnionCardTest < ActiveSupport::TestCase
  setup do
    @card = union_cards :one
  end

  test 'should be valid' do
    assert @card.valid?
  end

  test 'encrypted_agreement should be present' do
    @card.encrypted_agreement = nil
    assert @card.invalid?
  end

  test 'encrypted_agreement error messages should not include "Encrypted"' do
    @card.encrypted_agreement.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_AGREEMENT_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_agreement should be no longer than MAX_AGREEMENT_LENGTH' do
    @card.encrypted_agreement.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_AGREEMENT_LENGTH)
    assert @card.valid?

    @card.encrypted_agreement.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_AGREEMENT_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_department should be optional' do
    @card.encrypted_department = nil
    assert @card.valid?
  end

  test 'encrypted_department error messages should not include "Encrypted"' do
    @card.encrypted_department.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_DEPARTMENT_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_department should be no longer than MAX_DEPARTMENT_LENGTH' do
    @card.encrypted_department.ciphertext = \
      Base64.strict_encode64('a' * WorkGroup::MAX_DEPARTMENT_LENGTH)
    assert @card.valid?

    @card.encrypted_department.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_DEPARTMENT_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_email should be present' do
    @card.encrypted_email = nil
    assert @card.invalid?
  end

  test 'encrypted_email error messages should not include "Encrypted"' do
    @card.encrypted_email.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_EMAIL_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_email should be no longer than MAX_EMAIL_LENGTH' do
    @card.encrypted_email.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_EMAIL_LENGTH)
    assert @card.valid?

    @card.encrypted_email.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_EMAIL_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_employer_name should be present' do
    @card.encrypted_employer_name = nil
    assert @card.invalid?
  end

  test 'encrypted_employer_name error messages should not include "Encrypted"' do
    @card.encrypted_employer_name.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_EMPLOYER_NAME_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_employer_name should be no longer than MAX_EMPLOYER_NAME_LENGTH' do
    @card.encrypted_employer_name.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_EMPLOYER_NAME_LENGTH)
    assert @card.valid?

    @card.encrypted_employer_name.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_EMPLOYER_NAME_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_home_address_line1 should be present' do
    @card.encrypted_home_address_line1 = nil
    assert @card.invalid?
  end

  test 'encrypted_home_address_line1 error messages should not include "Encrypted"' do
    @card.encrypted_home_address_line1.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_HOME_ADDRESS_LINE1_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_home_address_line1 should be no longer than MAX_HOME_ADDRESS_LINE1_LENGTH' do
    @card.encrypted_home_address_line1.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_HOME_ADDRESS_LINE1_LENGTH)
    assert @card.valid?

    @card.encrypted_home_address_line1.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_HOME_ADDRESS_LINE1_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_home_address_line2 should be present' do
    @card.encrypted_home_address_line2 = nil
    assert @card.invalid?
  end

  test 'encrypted_home_address_line2 error messages should not include "Encrypted"' do
    @card.encrypted_home_address_line2.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_HOME_ADDRESS_LINE2_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_home_address_line2 should be no longer than MAX_HOME_ADDRESS_LINE2_LENGTH' do
    @card.encrypted_home_address_line2.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_HOME_ADDRESS_LINE2_LENGTH)
    assert @card.valid?

    @card.encrypted_home_address_line2.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_HOME_ADDRESS_LINE2_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_job_title should be optional' do
    @card.encrypted_job_title = nil
    assert @card.valid?
  end

  test 'encrypted_job_title error messages should not include "Encrypted"' do
    @card.encrypted_job_title.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_JOB_TITLE_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_job_title should be no longer than MAX_JOB_TITLE_LENGTH' do
    @card.encrypted_job_title.ciphertext = \
      Base64.strict_encode64('a' * WorkGroup::MAX_JOB_TITLE_LENGTH)
    assert @card.valid?

    @card.encrypted_job_title.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_JOB_TITLE_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_name should be present' do
    @card.encrypted_name = nil
    assert @card.invalid?
  end

  test 'encrypted_name error messages should not include "Encrypted"' do
    @card.encrypted_name.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_NAME_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_name should be no longer than MAX_NAME_LENGTH' do
    @card.encrypted_name.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_NAME_LENGTH)
    assert @card.valid?

    @card.encrypted_name.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_NAME_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_phone should be present' do
    @card.encrypted_phone = nil
    assert @card.invalid?
  end

  test 'encrypted_phone error messages should not include "Encrypted"' do
    @card.encrypted_phone.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_PHONE_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_phone should be no longer than MAX_PHONE_LENGTH' do
    @card.encrypted_phone.ciphertext = \
      Base64.strict_encode64('a' * UnionCard::MAX_PHONE_LENGTH)
    assert @card.valid?

    @card.encrypted_phone.ciphertext = \
      Base64.strict_encode64('a' * (1 + UnionCard::MAX_PHONE_LENGTH))
    assert @card.invalid?
  end

  test 'encrypted_shift should be optional' do
    @card.encrypted_shift = nil
    assert @card.valid?
  end

  test 'encrypted_shift error messages should not include "Encrypted"' do
    @card.encrypted_shift.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_SHIFT_LENGTH))
    @card.valid?
    assert_not @card.errors.full_messages.first.include? 'Encrypted'
  end

  test 'encrypted_shift should be no longer than MAX_SHIFT_LENGTH' do
    @card.encrypted_shift.ciphertext = \
      Base64.strict_encode64('a' * WorkGroup::MAX_SHIFT_LENGTH)
    assert @card.valid?

    @card.encrypted_shift.ciphertext = \
      Base64.strict_encode64('a' * (1 + WorkGroup::MAX_SHIFT_LENGTH))
    assert @card.invalid?
  end

  test 'signature_bytes should be Base64 encoded' do
    assert_equal @card.signature_bytes,
      Base64.strict_encode64(@card.attributes['signature_bytes'])
  end

  test 'signature_bytes should be present' do
    @card.signature_bytes = nil
    assert @card.invalid?
  end

  test 'signature_bytes should have the correct length' do
    @card.signature_bytes = Base64.decode64('deadbeef')
    assert @card.invalid?
  end

  test 'signed_at should be present' do
    @card.signed_at = nil
    assert @card.invalid?
  end

  test 'user should be present' do
    @card.user = nil
    assert @card.invalid?
  end

  test 'user should not be able to create multiple union cards' do
    assert_no_difference 'UnionCard.count' do
      @card.dup.save
    end
  end

  test 'user uniqueness error message should be custom' do
    duplicate = @card.dup
    assert duplicate.invalid?
    error = duplicate.errors[:user].first
    assert_not_nil error
    assert_not_includes error, 'taken'
  end

  test 'work_group should be optional' do
    @card.work_group = nil
    assert @card.valid?
  end

  test 'work_group should belong to user Org' do
    work_group_in_another_org = work_groups :two
    assert_not_equal work_group_in_another_org.org, @card.user.org
    @card.work_group = work_group_in_another_org
    assert @card.invalid?
  end

  test 'created_at_or_before should not include union_cards created after time' do
    card_created_at = union_cards(:one).created_at
    recent_cards = UnionCard.created_at_or_before(card_created_at)
    assert_not_equal UnionCard.count, recent_cards.count
    assert_not_empty recent_cards
    recent_cards.each do |card|
      assert_operator card.created_at, :<=, card_created_at
    end
  end

  test 'should create associated work_group on create when work_group_id absent and work_group info present' do
    card = @card.dup
    @card.destroy!
    card.work_group_id = nil
    assert_difference 'WorkGroup.count', 1 do
      card.save!
    end
    assert_not_nil card.work_group
    assert_equal card.work_group.encrypted_department.as_json,
      card.encrypted_department.as_json
    assert_equal card.work_group.encrypted_job_title.as_json,
      card.encrypted_job_title.as_json
    assert_equal card.work_group.encrypted_shift.as_json,
      card.encrypted_shift.as_json
  end

  test 'should not create associated work_group on update when work_group_id absent and work_group info present' do
    @card.work_group_id = nil
    assert_no_difference 'WorkGroup.count' do
      @card.save!
    end
  end

  test 'should not create assoiated work_group on create when work_group_id absent and work_group info absent' do
    card = @card.dup
    @card.destroy!
    card.work_group_id = nil
    card.encrypted_job_title = nil
    assert_no_difference 'WorkGroup.count' do
      card.save!
    end
  end

  test 'should create associated work_group on create when work_group_id present but not found and work_group info present' do
    card = @card.dup
    @card.destroy!
    assert_difference 'WorkGroup.count', 1 do
      card.save!
    end
    assert_not_nil card.work_group
    assert_equal card.work_group.encrypted_department.as_json,
      card.encrypted_department.as_json
    assert_equal card.work_group.encrypted_job_title.as_json,
      card.encrypted_job_title.as_json
    assert_equal card.work_group.encrypted_shift.as_json,
      card.encrypted_shift.as_json
  end

  test 'should not create associated work_group on update when work_group_id present but not found and work_group info present' do
    old_id = @card.work_group_id
    @card.update! work_group_id: nil
    WorkGroup.find(old_id).destroy!
    @card.work_group_id = old_id
    assert_no_difference 'WorkGroup.count' do
      begin
        @card.save!
      rescue
      end
    end
  end

  test 'should not created associated work_group on create when work_group_id present and found and work_group_info present' do
    card = @card.dup
    @card.work_group_id = nil # Prevents destroy_work_group_if_needed
    @card.destroy!
    assert_no_difference 'WorkGroup.count' do
      card.save!
    end
  end

  test 'should merge associated work_group errors into union_card errors on create' do
    card = @card.dup
    @card.destroy!
    card.work_group_id = nil

    error_type = 'test error'
    raises_exception = ->(_) do
      work_group = WorkGroup.new
      errors = ActiveModel::Errors.new work_group
      errors.add :base, error_type
      work_group.errors.merge! errors
      raise ActiveRecord::RecordInvalid.new work_group
    end
    card.user.created_work_groups.stub :create!, raises_exception do
      card.save
      first_error = card.errors.first
      assert_equal first_error.type, error_type
    end
  end

  test 'should destroy work_group on destroy if no other union_cards refernce it' do
    assert_equal 1, @card.work_group.union_cards.count
    assert_difference 'WorkGroup.count', -1 do
      @card.destroy!
    end
  end

  test 'should not destroy work_group on destroy if other union_cards still reference it' do
    other_union_card = union_cards :two
    other_union_card.update! work_group: @card.work_group
    assert @card.work_group.union_cards.many?
    assert_no_difference 'WorkGroup.count' do
      @card.destroy!
    end
  end
end
