class Thing < ThingTemplate
  include Mongoid::Document

  # a thing is something the user has
  # done on a particular date

  field :name, type: String
  field :date, type: Date
  index({ date: 1 }, { name: "date_index" })

  # thing_template_id might not map to an existing thing
  # (ie the thing_template may have been deleted)
  # it is used to prvent duplicate things being created
  field :thing_template_id, type: Moped::BSON::ObjectId, default: nil

  validates :name, length: {minimum: 1, maximum: 255}

  embedded_in :user
end
