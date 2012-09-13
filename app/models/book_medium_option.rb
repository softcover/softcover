class BookMediumOption < ActiveRecord::Base
  attr_accessible nil

  belongs_to :medium, class_name: 'BookMedium', foreign_key: :book_medium_id
  belongs_to :option, class_name: 'BookOption', foreign_key: :book_option_id
end
