class Book < ActiveRecord::Base
  attr_accessible :title

  belongs_to :user

  has_many :media, class_name: 'BookMedium', dependent: :destroy
  has_many :options, class_name: 'BookOption', dependent: :destroy

  scope :owned_by, lambda{|user| joins(media:{options:{purchases: :ownerships}}).where('ownerships.user_id = ?', user.id)}

  def owners
    User.owners_of self
  end
end
