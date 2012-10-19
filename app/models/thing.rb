class Thing < ThingTemplate
  include Mongoid::Document

  validate :check_not_duplicate, :on => :create

  # a thing is something the user has
  # done on a particular date

  field :name, type: String
  field :date, type: Date
  index({ date: 1 }, { name: "date_index" })

  # thing_template_id might not map to an existing thing
  # (ie the thing_template may have been deleted)
  # but it is used to prevent duplicate things being created
  # which could happen if someone clicks faster than ajax can
  # update the display
  field :thing_template_id, type: Moped::BSON::ObjectId, default: nil
  index({ thing_template_id: 1 }, { name: "thing_template_id_index" })

  validates :name, length: {minimum: 1, maximum: 255}

  embedded_in :user

  def check_not_duplicate
    # don't check unless thing_template_id is set 
    # (provides backwards compatibility with old things)
    return unless thing_template_id
    
    # check not duplicate 
    if user.things.where(thing_template_id: thing_template_id, date: date).count > 1 
      errors.add(:thing_template_id, "must be unique for date #{date}")
    end
  end
end
