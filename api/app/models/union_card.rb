class UnionCard < ApplicationRecord
  include Encryptable

  scope :created_at_or_before, ->(time) { where(created_at: ..time) }

  MAX_AGREEMENT_LENGTH = \
    93 + Org::MAX_NAME_LENGTH + Org::MAX_EMPLOYER_NAME_LENGTH
  MAX_EMAIL_LENGTH = Org::MAX_EMAIL_LENGTH
  MAX_EMPLOYER_NAME_LENGTH = Org::MAX_EMPLOYER_NAME_LENGTH
  MAX_HOME_ADDRESS_LINE1_LENGTH = 100
  MAX_HOME_ADDRESS_LINE2_LENGTH = 100
  MAX_NAME_LENGTH = 100
  MAX_PHONE_LENGTH = 20
  SIGNATURE_LENGTH = 88

  belongs_to :user
  belongs_to :work_group

  has_one :org, through: :user

  validates :signature_bytes,
    presence: true,
    length: { is: SIGNATURE_LENGTH }
  validates :signed_at, presence: true
  validates :user, uniqueness: true
  validates :work_group, presence: true, same_org: :user

  after_destroy :destroy_work_group_if_needed

  before_validation :create_work_group_if_needed, on: :create

  has_encrypted :agreement, present: true, max_length: MAX_AGREEMENT_LENGTH
  has_encrypted :email, present: true, max_length: MAX_EMAIL_LENGTH
  has_encrypted :employer_name,
    present: true,
    max_length: MAX_EMPLOYER_NAME_LENGTH
  has_encrypted :department, max_length: WorkGroup::MAX_DEPARTMENT_LENGTH
  has_encrypted :home_address_line1, present: true,
    max_length: MAX_HOME_ADDRESS_LINE1_LENGTH
  has_encrypted :home_address_line2, present: true,
    max_length: MAX_HOME_ADDRESS_LINE2_LENGTH
  has_encrypted :job_title, present: true,
    max_length: WorkGroup::MAX_JOB_TITLE_LENGTH
  has_encrypted :name, present: true, max_length: MAX_NAME_LENGTH
  has_encrypted :phone, present: true, max_length: MAX_PHONE_LENGTH
  has_encrypted :shift, present: true, max_length: WorkGroup::MAX_SHIFT_LENGTH

  # This should only be used when joined with user
  def public_key_bytes
    begin
      OpenSSL::PKey::EC.new(attributes['public_key_bytes']).to_pem
    rescue
      nil
    end
  end

  def signature_bytes=(value)
    begin
      write_attribute :signature_bytes, Base64.strict_decode64(value)
    rescue
      write_attribute :signature_bytes, nil
    end
  end

  def signature_bytes
    begin
      Base64.strict_encode64 attributes['signature_bytes']
    rescue
      nil
    end
  end

  private

  def create_work_group_if_needed
    return if work_group_id && org.work_groups.exists?(work_group_id)

    begin
      create_work_group! encrypted_department:,
        encrypted_job_title:,
        encrypted_shift:,
        user_id:
    rescue ActiveRecord::RecordInvalid
      errors.add :work_group, :invalid
    end
  end

  def destroy_work_group_if_needed
    work_group.destroy! unless work_group.union_cards.any?
  end
end
