class EncryptedMessage
  include ActiveModel::Model

  BYTE_LENGTH_AUTH_TAG = 16
  BYTE_LENGTH_NONCE = 12
  ERROR_MESSAGE_UNEXPECTED_BASE64_BYTE_LENGTH = 'had unexpected byte length when decoded from base64'
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

  def decoded_ciphertext_length
    decoded_attribute_length :ciphertext
  end

  def self.dump(value)
    if value.respond_to? :attributes
      value.attributes
    else
      value.to_h
    end
  end

  def self.load(hash)
    EncryptedMessage.new(hash)
  end

  def self.permitted_params(attribute)
    { "encrypted_#{attribute}" => KEYS }
  end

  private

  def base64_decoded_byte_length(attribute_name, byte_length)
    length = decoded_attribute_length attribute_name
    if length != byte_length
      errors.add(attribute_name, ERROR_MESSAGE_UNEXPECTED_BASE64_BYTE_LENGTH)
    end
  end

  def decoded_attribute_length(attribute_name)
    attribute = send(attribute_name)
    return 0 if attribute.blank?
    return Base64.decode64(attribute).length
  end
end
