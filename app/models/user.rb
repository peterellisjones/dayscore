class User
  include Mongoid::Document

  before_create :generate_rand_str
  before_create :set_default_thing_templates

  # time diff is the difference between the users local time and the server time in seconds
  # server time + time diff = local time
  # this is used for calculating when days change according to the user
  field :time_diff, type: Integer, default: 0

  def update_user_time_diff(user_now)
    user_now = Time.parse(user_now)
    self.time_diff = user_now - Time.now
    # don't need to save since this model will be saved elsewhere
  end

  # rand_str is a random string that is used to create the url in the form of
  # /rand_str
  field :rand_str, type: String

  def generate_rand_str
    chars = [('a'..'z'),('A'..'Z'),('0'..'9')].map{|i| i.to_a}.flatten
    self.rand_str = (0...20).map{ chars[rand(chars.length)] }.join
  end

  def uri
    self.rand_str
  end

  # thing is something the user has done
  # it has a name and an associated date
  embeds_many :things

  # a thing template is something the user
  # is trying to do regularly
  embeds_many :thing_templates

  def set_default_thing_templates
    self.thing_templates << ThingTemplate.new(name: "woke up early")
    self.thing_templates << ThingTemplate.new(name: "did 20 minutes of exercise")
    self.thing_templates << ThingTemplate.new(name: "cleared my inbox")
    self.thing_templates << ThingTemplate.new(name: "ate 3 nutritious meals")
  end

  def create_thing(thing_template)
    thing = Thing.new(name: thing_template.name, datetime: DateTime.now)
    self.things << thing
    self.save
    thing
  end

  # THIS IS BROKEN...
  # NEED TO GUESS USERS TIMEZONE AND DO IT LIKE THAT
  def user_today
    user_time = DateTime.now + time_diff
    if user_time.hour < 3
      user_time = user_time.yesterday.midnight
    else
      user_time = user_time.midnight
    end
    user_time
  end

  def todays_things
    self.things.where(:datetime.gte => Date.today).entries
  end

  def points_this_week
    self.things.where(:datetime.gte => Date.today.at_beginning_of_week).count
  end

  def points_this_month
    self.things.where(:datetime.gte => Date.today.at_beginning_of_month).count
  end

  def points_yesterday
    self.things.where(datetime: Date.today.yesterday).count
  end

  def points_last_week
    last_week = Date.today.at_beginning_of_week - 1.week
    self.things.where(:datetime.gte => last_week, :datetime.lte => last_week.at_end_of_week).count
  end

  def points_last_month
    last_month = Date.today.at_beginning_of_month - 1.month
    self.things.where(:datetime.gte => last_month, :datetime.lte => last_month.at_end_of_month).count
  end

  def points_all_time
    self.things.count
  end
end
