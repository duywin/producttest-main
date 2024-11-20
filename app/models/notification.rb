class Notification < ApplicationRecord
  belongs_to :admin, class_name: "Account"
  scope :unread, -> { where(read: false) }
end
