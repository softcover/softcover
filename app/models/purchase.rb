class Purchase < ActiveRecord::Base
  attr_accessible nil

  belongs_to :user
  belongs_to :book_option

  has_many :ownerships

  after_create :create_user_ownership

  def create_user_ownership
    ownership = ownerships.build
    ownership.user = user
    ownership.save
  end
end
