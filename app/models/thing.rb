class Thing
  include Mongoid::Document

  field :name, type: String
  field :date, type: Date

  embedded_in :user
end
