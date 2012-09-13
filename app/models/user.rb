class User < ActiveRecord::Base
  attr_accessible :email
  attr_accessor :password, :password_confirmation

  has_many :books

  has_many :ownerships, dependent: :destroy
  has_many :purchases, dependent: :destroy

  scope :owners_of, lambda{|book| joins(ownerships:{purchase: :option}).where('book_options.book_id = ?', book.id)}

  def owned_books
    Book.owned_by self
  end

  def owned_media
    BookMedium.owned_by self
  end
end
