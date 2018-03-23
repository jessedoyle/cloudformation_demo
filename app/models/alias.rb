class Alias < ApplicationRecord
  validates :instance_id, :value, presence: true
end
