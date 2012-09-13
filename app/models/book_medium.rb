class BookMedium < ActiveRecord::Base
  attr_accessible :name, :url

  belongs_to :book

  has_many :medium_options, class_name: 'BookMediumOption', dependent: :destroy
  has_many :options, through: :medium_options

  scope :owned_by, lambda{|user| joins(options:{purchases: :ownerships}).where('ownerships.user_id = ?', user.id)}
end
