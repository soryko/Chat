class Message < ApplicationRecord
  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  validates :content, presence: true, length: { minimum: 1, maximum: 10000 }
  
  scope :ordered, -> { order(:created_at) }
  scope :recent, -> { order(created_at: :desc) }
end
