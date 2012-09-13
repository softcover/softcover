class Ownership < ActiveRecord::Base
  attr_accessible :email

  belongs_to :user
  belongs_to :purchase
end
