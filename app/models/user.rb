class User < ApplicationRecord
  PUBLIC_KEY_LENGTH = 294

  belongs_to :org

  validates :public_key,
    presence: true,
    length: { is: PUBLIC_KEY_LENGTH }

  before_validation :convert_public_key_to_binary, on: :create

  private

    def convert_public_key_to_binary
      begin
        self.public_key = OpenSSL::PKey::RSA.new(self.public_key).to_der
      rescue => exception
        self.public_key = nil
      end
    end
end
