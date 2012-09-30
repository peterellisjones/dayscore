class Thing
  include Mongoid::Document

  field :name, type: String
  field :datetime, type: DateTime

  embedded_in :user
end
