class ThingTemplate
  include Mongoid::Document

  # a thing_template describes something
  # the user wants to do regularly

  field :name, type: String
  field :date, type: Date

  validates :name, length: {minimum: 1, maximum: 255}
  
  embedded_in :user
end
