class User < ActiveRecord::Base
  attr_accessible :email
  attr_accessor :password, :password_confirmation

  has_many :ownerships, dependent: :destroy
  has_many :purchases, dependent: :destroy

  def books
    Book.joins(media:{options:{purchases: :ownerships}}).where('ownerships.user_id = ?', id)
  end

  def accessible_media
    BookMedium.joins(options:{purchases: :ownerships}).where('ownerships.user_id = ?', id)
  end
end
