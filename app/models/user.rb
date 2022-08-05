class User < ApplicationRecord
  PUBLIC_KEY_LENGTH = 294

  belongs_to :org

  validates :public_key,
    presence: true,
    length: { is: PUBLIC_KEY_LENGTH }
end
