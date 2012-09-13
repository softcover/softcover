class Book < ActiveRecord::Base
  attr_accessible :title

  belongs_to :user

  has_many :media, class_name: 'BookMedium', dependent: :destroy
  has_many :options, class_name: 'BookOption', dependent: :destroy

  has_many :purchases, through: :options
  has_many :ownerships, through: :purchases
  has_many :owners, through: :ownerships, class_name: 'User'

  scope :owned_by, lambda{|user| joins(options:{purchases: :ownerships}).where('ownerships.user_id = ?', user.id)}

  def owners
    User.owners_of self
  end
end
