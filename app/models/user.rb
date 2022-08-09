class User < ApplicationRecord
  PUBLIC_KEY_LENGTH = 294

  belongs_to :org

  validates :public_key_bytes,
    presence: true,
    length: { is: PUBLIC_KEY_LENGTH }

  before_validation :convert_public_key_to_binary, on: :create

  def public_key
    OpenSSL::PKey::RSA.new(public_key_bytes)
  end

  private

    def convert_public_key_to_binary
      begin
        public_key_bytes = OpenSSL::PKey::RSA.new(self.public_key_bytes).to_der
        self.public_key_bytes = public_key_bytes
      rescue => exception
        self.public_key_bytes = nil
      end
    end
end
