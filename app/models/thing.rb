class Thing < ThingTemplate
  include Mongoid::Document

  # a thing is something the user has
  # done on a particular date

  field :name, type: String
  field :date, type: Date

  validates :name, length: {minimum: 1, maximum: 255}

  embedded_in :user
end
