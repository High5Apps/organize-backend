class WorkGroup < ApplicationRecord
  include Encryptable

  MAX_DEPARTMENT_LENGTH = 100
  MAX_JOB_TITLE_LENGTH = 100
  MAX_SHIFT_LENGTH = 3

  belongs_to :creator, class_name: 'User', foreign_key: :user_id

  has_many :union_cards
  has_many :users, through: :union_cards

  has_one :org, through: :creator

  has_encrypted :department, max_length: MAX_DEPARTMENT_LENGTH
  has_encrypted :job_title, present: true, max_length: MAX_JOB_TITLE_LENGTH
  has_encrypted :shift, present: true, max_length: MAX_SHIFT_LENGTH
end
