class EncryptedMessage
  include ActiveModel::API

  BYTE_LENGTH_AUTH_TAG = 16
  BYTE_LENGTH_NONCE = 12
  KEYS = [:c, :n, :t]

  attr_accessor *KEYS
  alias_attribute :ciphertext, :c
  alias_attribute :nonce, :n
  alias_attribute :auth_tag, :t

  validates :ciphertext, presence: true
  validates :nonce, presence: true
  validates :auth_tag, presence: true

  validate -> { base64_decoded_byte_length :nonce, BYTE_LENGTH_NONCE }
  validate -> { base64_decoded_byte_length :auth_tag, BYTE_LENGTH_AUTH_TAG }

  def attributes
    instance_values
  end

  def blank?
    decoded_ciphertext_length == 0
  end

  def decoded_ciphertext_length
    decoded_attribute_length :ciphertext
  end

  def self.dump(value)
    value.blank? ? nil : value.as_json
  end

  def self.load(hash)
    return nil if hash.nil?

    filtered_hash = hash.slice *KEYS.map(&:to_s)
    EncryptedMessage.new filtered_hash
  end

  def self.permitted_params(attribute)
    { "encrypted_#{attribute}" => KEYS }
  end

  private

  def base64_decoded_byte_length(attribute_name, byte_length)
    length = decoded_attribute_length attribute_name
    if length != byte_length
      errors.add attribute_name, :unexpected_base64_byte_length
    end
  end

  def decoded_attribute_length(attribute_name)
    attribute = send(attribute_name)
    return 0 if attribute.blank?
    return Base64.decode64(attribute).length
  end
end
