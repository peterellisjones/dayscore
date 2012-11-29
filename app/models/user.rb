class User
  include Mongoid::Document

  before_create :set_default_thing_templates

  # created_at is theoretically the date the user was created... in practice 
  # we want this date in the user's time-zone so we don't actually create it
  # until the first call to update_user_time_diff (which is when client-side code
  # sends the user's time)
  # note Date and not Datetime, since we want to round JS timestamps to nearest 24 hours
  field :created_at, type: Date

  # time diff is the difference between the user's local time and UTC in seconds
  # UTC + time_diff = user's local time
  # this is used for calculating when days change according to the user
  field :time_diff, type: Integer, default: 0

  # update_user_time_diff called as before_filter to create_thing and create_template
  def update_user_time_diff (user_timezone_offset_minutes)
    time_diff = - user_timezone_offset_minutes * 60
    # only dirty attribute if necesary  
    self.time_diff = time_diff if self.time_diff != time_diff
    # set created_at if not yet set
    self.created_at = user_today if self.created_at == nil
    # don't need save since this will be called by real purpose of 
    # controller action
  end

  def user_created_at
    self.created_at + self.time_diff
  end

  # rand_str is a random string used as the user ID
  field :rand_str, type: String, pre_processed: true, default: -> { get_random_string }
  index "rand_str" => 1

  # question... are 20 chars enough?
  # this gives 36^20 possibilities, or approx 10^31
  # server handles maybe 10^2 req/sec
  # max users say: 10^5
  # so 10^31 / (10^5 * 10^2) = rough estimate 10^24 seconds for a collision
  # answer.. yes - ie, no chance of collision
  # but... since this uses a pseudorandom RNG, someone could in theory deduce subsequent strings
  # but they'd have to really want it.. and the data is going to be pretty useless anyway
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
    DEFAULT_THING_TEMPLATES.each { |t| self.thing_templates << ThingTemplate.new(name: t) }
  end

  def create_thing(thing_template, date = nil)
    date ||= user_today
    thing = Thing.new(name: thing_template.name, date: date, thing_template_id: thing_template._id)
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

  def things_by_date date
    self.things.where(date: date).entries
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
  def chart_data(date = nil)
    thing_hash = {}
    # create hash index by JS time stamp (ie milliseconds since 1970)
    self.things.each do |thing|
      js_stamp = thing.date.to_time.to_i * 1000
      thing_hash[js_stamp] ||= 0
      thing_hash[js_stamp] += 1
    end

    # force today ||= 0 (max x axis)
    thing_hash[user_today.to_time.to_i * 1000] ||= 0

    # force created_at ||= 0 (min x axis)
    if self.created_at != nil
      thing_hash[self.created_at.to_time.to_i * 1000] ||= 0
    end

    # force active date ||= 0
    if date
      thing_hash[date.to_time.to_i * 1000] ||= 0
    end

    thing_hash
  end

  field :email, type: String

  def send_email
    unless self.email
      throw "No email for this user"
    end
  end

  # test data - create some random things for the last 2 months
  def create_test_data
    Date.today.downto(Date.today - 2.months) do |day|
      self.thing_templates.each do |t|
        if Random.rand(10) >= 8
          self.things << Thing.new(name: t.name, date: day, thing_template_id: t._id)
        end
      end
    end 
    self.save
  end

  def self.cleanup_old_users
    # do this every month or so (cron job?)
    # to empty DB of inactive users
    cutoff = Date.today - 1.month
    Rails.logger.info "Deleting users created on or before #{cutoff}"
    total_users = User.count
    User.each do |u|
      # if created over a month ago...
      if u.created_at != nil && u.created_at <= cutoff
        # if user didn't make any changes
        if u.things.count == 4 && u.things.all? { |t| DEFAULT_THING_TEMPLATES.include? t.name }
          Rails.logger.info "DELETING USER #{u.inspect}"
          u.destroy
        end
      end
    end
    deleted_users = total_users - User.count
    Rails.logger.info "Deleted #{deleted_users}/#{total_users} (#{100 * deleted_users.to_f/total_users}%)"
  end
end
