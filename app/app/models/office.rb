class Office < ApplicationRecord
  has_many :terms
  has_many :users, through: :terms

  validates :name, presence: true
end
