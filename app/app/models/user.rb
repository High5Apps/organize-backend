class User < ApplicationRecord
  PUBLIC_KEY_LENGTH = 91

  attr_writer :private_key

  belongs_to :org, optional: true

  has_many :shared_connections,
    foreign_key: 'sharer_id', 
    class_name: 'Connection'
  has_many :scanners, through: :shared_connections

  has_many :scanned_connections,
    foreign_key: 'scanner_id',
    class_name: 'Connection'
  has_many :sharers, 
    through: :scanned_connections, 
    class_name: 'User'

  validates :public_key_bytes,
    presence: true,
    length: { is: PUBLIC_KEY_LENGTH }

  before_validation :convert_public_key_to_binary, on: :create
  before_update :set_pseudonym,
    if: -> { will_save_change_to_org_id? from: nil }

  def create_auth_token(expiration, scope)
    payload = JsonWebToken.payload(id, expiration, scope)
    JsonWebToken.encode(payload, private_key)
  end

  def public_key
    OpenSSL::PKey::EC.new(public_key_bytes)
  end

  def directly_connected_to?(user_id)
    Connection.directly_connected?(id, user_id)
  end

  def connection_to(user_id)
    Connection.between(id, user_id)
  end

  private

    attr_reader :private_key

    def convert_public_key_to_binary
      begin
        public_key_bytes = OpenSSL::PKey::EC.new(self.public_key_bytes).to_der
        self.public_key_bytes = public_key_bytes
      rescue => exception
        self.public_key_bytes = nil
      end
    end

    def set_pseudonym
      self.pseudonym = org.next_pseudonym
    end
end