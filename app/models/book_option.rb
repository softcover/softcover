class BookOption < ActiveRecord::Base
  attr_accessible :name, :price_in_cents, :price_in_dollars

  belongs_to :book

  has_many :medium_options, class_name: 'BookMediumOption'
  has_many :media, through: :medium_options

  has_many :purchases

  scope :by_name, lambda{|name| where(name: name)}

  def price_in_dollars=(dollars)
    self.price_in_cents = dollars * 100
  end

  def price_in_dollars
    (self.price_in_cents || 0) / 100
  end
end
