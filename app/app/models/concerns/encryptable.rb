module Encryptable
  extend ActiveSupport::Concern

  class_methods do
    def has_encrypted(attribute, present: false, max_length: nil)
      encrypted_attribute_name = "encrypted_#{attribute}"
      validate_max_length_method_name = "validate_#{attribute}_max_length"

      validate validate_max_length_method_name.to_sym if max_length
      validates_presence_of encrypted_attribute_name if present

      serialize encrypted_attribute_name, coder: EncryptedMessage

      define_method(validate_max_length_method_name) do
        length = send(encrypted_attribute_name).decoded_ciphertext_length
        if length > max_length
          errors.add(encrypted_attribute_name,
            "is too long. Emojis count more. Length: #{length}, max: #{max_length}")
        end
      end
    end
  end
end
