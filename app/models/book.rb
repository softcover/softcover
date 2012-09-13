class Book < ActiveRecord::Base
  attr_accessible :title

  has_many :media, class_name: 'BookMedium', dependent: :destroy
  has_many :options, class_name: 'BookOption', dependent: :destroy
end
