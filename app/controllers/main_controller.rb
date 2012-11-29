class MainController < ApplicationController
  before_filter :get_or_create_user, only: [:home, :date]
  before_filter :get_user, except: [:home, :date, :create_user]
  before_filter :update_user_time_diff, only: [:create_thing, :create_template]
  before_filter :get_date

  def home
    if @date
      @things = @user.things_by_date(@date)
    else
      @things = @user.todays_things
    end
  end

  def get_date
    if params.has_key? :date
      @date = Date.parse(params[:date])
      @date = nil if @date == @user.user_today
    end
  end

  def email
    @user.send_email
    render :json => "Email sent"
  end

  def get_or_create_user
    @user = User.where(rand_str: params[:user_id]).first
    unless @user
      create_user   
    end    
  end

  def create_user
    @user = User.create
    if @user 
      redirect_to user_path(@user.rand_str)
    else
      Rails.logger.error "Couldn't create user"
    end
  end

  # called before all ajax requests, sets @user
  def get_user
    begin
      @user = User.where(rand_str: params[:user_id]).first
    rescue
      render :json => "Couldn't find user", :status => :unprocessable_entity and return
    end
  end

  # called before all ajax requests, sets user's time difference
  def update_user_time_diff
    if params[:timezone_offset_minutes]
      @user.update_user_time_diff params[:timezone_offset_minutes].to_i
    end
  end

  def create_thing
    thing_template = @user.thing_templates.where(id: params[:template_id]).first
    if thing_template.nil?
      render :json => "Couldn't find thing template", :status => :unprocessable_entity and return
    end
    if @date
      thing = @user.create_thing(thing_template, @date)
    else
      thing = @user.create_thing(thing_template)
    end
    render :json => thing
  end

  def create_template
    if params[:name] == nil
      render :json => "No name!", :status => :unprocessable_entity and return
    end
    thing_template = ThingTemplate.new name: params[:name]
    @user.thing_templates << thing_template
    render :json => thing_template
  end

  def destroy_thing
    thing = @user.things.where(id: params[:thing_id]).first
    if thing == nil
      render :json => "Couldn't find thing", :status => :unprocessable_entity and return
    end
    thing_template = @user.thing_templates.where(name: thing.name).first
    if thing_template == nil
      render :json => "Couldn't find thing template", :status => :unprocessable_entity and return
    end
    thing.destroy
    # display template so client can switch thing for template
    render :json => thing_template
  end

  def destroy_template
    template = @user.thing_templates.where(id: params[:template_id]).first
    if template == nil
      render :json => "Couldn't find template", :status => :unprocessable_entity and return
    end
    template.destroy
    # return ID so client can delete from screen
    render :json => { _id: params[:template_id] }
  end

  def edit_thing
    thing = @user.things.where(id: params[:thing_id]).first
    old_name = thing.name
    if thing == nil
      render :json => "Couldn't find thing", :status => :unprocessable_entity and return
    elsif params[:name] == nil
      render :json => "No name!", :status => :unprocessable_entity and return
    end
    
    # need to update template too
    thing_template = @user.thing_templates.where(name: old_name).first
    thing_template.update_attribute(:name, params[:name])

    thing.update_attributes(name: params[:name], thing_template_id: thing_template._id)

    render :json => thing
  end

  def edit_template
    thing_template = @user.thing_templates.where(id: params[:template_id]).first
    if thing_template == nil
      render :json => "Couldn't find thing template", :status => :unprocessable_entity and return
    end
    if params[:name] == nil
      render :json => "No name!", :status => :unprocessable_entity and return
    end
    thing_template.update_attribute(:name, params[:name])
    render :json => thing_template
  end

  def export_csv
    c = CSV.generate do |csv|
      csv << ['date', 'item']
      @user.things.each do |t|
        csv << [t.date, t.name]
      end
    end
    send_data c, :filename => "dayscore.csv"
  end
end
