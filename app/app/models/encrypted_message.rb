class EncryptedMessage
  include ActiveModel::Model

  BYTE_LENGTH_AUTH_TAG = 16
  BYTE_LENGTH_NONCE = 12
  ERROR_MESSAGE_UNEXPECTED_BASE64_BYTE_LENGTH = 'had unexpected byte length when decoded from base64'

  attr_accessor :c, :n, :t

  validates :c, presence: true
  validates :n, presence: true
  validates :t, presence: true

  validate -> { base64_decoded_byte_length :n, BYTE_LENGTH_NONCE }
  validate -> { base64_decoded_byte_length :t, BYTE_LENGTH_AUTH_TAG }

  def attributes
    instance_values
  end

  def decoded_byte_length
    return 0 if c.blank?
    return Base64.decode64(c).length
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

  private

  def base64_decoded_byte_length(attribute_name, byte_length)
    attribute = send(attribute_name)
    if attribute.blank? || Base64.decode64(attribute).length != byte_length
      errors.add(attribute_name, ERROR_MESSAGE_UNEXPECTED_BASE64_BYTE_LENGTH)
    end
  end
end
