class ThingTemplate
  include Mongoid::Document

  field :name, type: String

  validates :name, length: {minimum: 1, maximum: 255}, uniqueness: true

  embedded_in :user
end
