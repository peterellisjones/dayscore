class User
  include Mongoid::Document

  before_create :set_default_thing_templates

  # created_at is theoretically the date the user was created... in practise 
  # we want this date in the user's time-zone so we don't actually create it
  # until the first call to update_user_time_diff
  field :created_at, type: Date

  # time diff is the difference between the users local time and UTC in seconds
  # UTC + time diff = local time
  # this is used for calculating when days change according to the user
  field :time_diff, type: Integer, default: 0

  def update_user_time_diff (user_timezone_offset_minutes)
    self.time_diff = - user_timezone_offset_minutes * 60 
    if self.created_at == nil
      self.created_at = user_today
    end
  end

  def user_created_at
    (self.created_at + self.time_diff)
  end

  # rand_str is a random string used as the user ID
  field :rand_str, type: String, pre_processed: true, default: -> { get_random_string }
  index "rand_str" => 1

  # question... are 20 chars enough for security?
  # this gives 26^20 possibilities, or 2 * 10^28
  # answer.. yes
  # since this uses a pseudorandom RNG, someone could in theory deduce subsequent strings
  def get_random_string
    chars = [('a'..'z'),('0'..'9')].map {|i| i.to_a}.flatten
    str = (0...20).map { chars[rand(chars.length)] }.join
  end

  # thing is something the user has done
  # it has a name and an associated date
  # index on date to help with points calculation
  embeds_many :things
  index({ "things.date" => 1 }, { name: "things_date_index" })

  # a thing template is something the user
  # is trying to do regularly
  embeds_many :thing_templates

  DEFAULT_THING_TEMPLATES = [
    "woke up early",
    "did 20 minutes of exercise",
    "cleared my inbox",
     "ate 3 nutritious meals"]

  def set_default_thing_templates
    DEFAULT_THING_TEMPLATES.each do |t|
      self.thing_templates << ThingTemplate.new(name: t)
    end
  end

  def create_thing(thing_template)
    thing = Thing.new name: thing_template.name, date: user_today
    self.things << thing
    self.save
    thing
  end

  # returns what day it is for the user
  # this is used to save the date in the users time frame
  def user_today
    if self.time_diff != nil
      user_time = Time.now.utc + self.time_diff
    else
      user_time = Time.now.utc
    end
    
    # consider the day to change at 3AM 
    if user_time.hour < 3
      user_day = user_time.yesterday.midnight.to_date
    else
      user_day = user_time.midnight.to_date
    end
    user_day
  end

  def todays_things
    self.things.where(date: user_today).entries
  end

  def points_this_week
    self.things.where(:date.gte => user_today.at_beginning_of_week).count
  end

  def points_this_month
    self.things.where(:date.gte => user_today.at_beginning_of_month).count
  end

  def points_yesterday
    self.things.where(date: user_today.yesterday).count
  end

  def points_last_week
    last_week = user_today.at_beginning_of_week - 1.week
    self.things.where(:date.gte => last_week, :date.lte => last_week.at_end_of_week).count
  end

  def points_last_month
    last_month = user_today.at_beginning_of_month - 1.month
    self.things.where(:date.gte => last_month, :date.lte => last_month.at_end_of_month).count
  end

  def points_all_time
    self.things.count
  end

  # returns chart data as mapping from JS timestamp to number of things that day.
  # if the extremes of the chart have no data, it puts zeros there to enforce the
  # length of the chart (ie from created_at to today)
  def chart_data
    thing_hash = {}
    # create hash index by JS time stamp (ie milliseconds since 1970)
    self.things.each do |thing|
      js_stamp = thing.date.to_time.to_i * 1000
      thing_hash[js_stamp] ||= 0
      thing_hash[js_stamp] += 1
    end

    # force today = 0
    js_stamp = user_today.to_time.to_i * 1000
    thing_hash[js_stamp] ||= 0

    # force created_at = 0
    if self.created_at != nil
      js_stamp = self.created_at.to_time.to_i * 1000
      thing_hash[js_stamp] ||= 0
    end

    thing_hash
  end

  # test data - create some random things
  def create_test_data
    Date.today.downto(Date.today - 2.months) do |day|
      self.thing_templates.each do |t|
        if Random.rand(10) >= 8
          self.things << Thing.new(name: t.name, date: day)
        end
      end
    end 
    self.save
  end

  def self.cleanup_old_users
    cutoff = Date.today - 1.month
    Rails.logger.info "Deleting users created on or before #{cutoff}"
    total_users = User.count
    User.each do |u|
      # if older than a month...
      if u.created_at != nil && u.created_at <= cutoff
        # if only default things
        if u.things.count == 4 && u.things.all? { |t| DEFAULT_THING_TEMPLATES.include? t.name }
          puts "DELETING USER #{u.inspect}"
          u.destroy
        end
      end
    end
    deleted_users = total_users - User.count
    Rails.logger.info "Deleted #{deleted_users}/#{total_users} (#{100 * deleted_users.to_f/total_users}%)"
  end
end
