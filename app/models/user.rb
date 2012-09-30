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
    thing = Thing.new name: thing_template.name, date: user_today
    self.things << thing
    self.save
    thing
  end

  # returns what the day it is for the user
  # this is used to save the date in the users time frame
  def user_today
    user_time = Time.now + time_diff
    if user_time.hour < 3
      user_day = user_time.yesterday.midnight.to_date
    else
      user_day = user_time.midnight.to_date
    end
    user_day
  end

  def todays_things
    self.things.where(date: Date.today).entries
  end

  def points_this_week
    self.things.where(:date.gte => Date.today.at_beginning_of_week).count
  end

  def points_this_month
    self.things.where(:date.gte => Date.today.at_beginning_of_month).count
  end

  def points_yesterday
    self.things.where(date: Date.today.yesterday).count
  end

  def points_last_week
    last_week = Date.today.at_beginning_of_week - 1.week
    self.things.where(:date.gte => last_week, :date.lte => last_week.at_end_of_week).count
  end

  def points_last_month
    last_month = Date.today.at_beginning_of_month - 1.month
    self.things.where(:date.gte => last_month, :date.lte => last_month.at_end_of_month).count
  end

  def points_all_time
    self.things.count
  end

  # returns chart data as mapping from JS timestamp to number of things that day.
  def chart_data
    thing_hash = {}
    self.things.each do |thing|
      js_stamp = thing.date.to_time.to_i * 1000
      thing_hash[js_stamp] ||= 0
      thing_hash[js_stamp] += 1
    end
    thing_hash
  end

  # test data - 
  def create_test_data
    Date.today.downto(Date.today - 3.months) do |day|
      self.thing_templates.each do |t|
        if Random.rand(3) >= 2
          self.things << Thing.new(name: t.name, date: day)
        end
        if Random.rand(3) >= 2
          self.things << Thing.new(name: t.name, date: day)
        end
        if Random.rand(3) >= 2
          self.things << Thing.new(name: t.name, date: day)
        end
        if Random.rand(3) >= 2
          self.things << Thing.new(name: t.name, date: day)
        end
      end
    end 
    self.save
  end
end
