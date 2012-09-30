class MainController < ApplicationController
  before_filter :get_user, except: [:home, :create_user]
  before_filter :update_user_time_diff, only: :create_thing

  def home
    @user = User.where(rand_str: params[:user_id]).first
    if @user == nil
      create_user
    end
  end

  def create_user
    user = User.create!
    if Rails.env == 'development'
      user.create_test_data
    end
    redirect_to home_path(user.uri)
  end

  def get_user
    @user = User.where(rand_str: params[:user_id]).first
    if @user == nil
      render :json => "Couldn't find user", :status => :unprocessable_entity and return
    end
  end

  def update_user_time_diff
    if params[:now]
      @user.update_user_time_diff params[:now]
    end
  end

  def create_thing
    thing_template = @user.thing_templates.where(id: params[:template_id]).first
    if thing_template == nil
      render :json => "Couldn't find thing template", :status => :unprocessable_entity and return
    end
    thing = @user.create_thing(thing_template)
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
    render :json => thing_template
  end

  def destroy_template
    template = @user.thing_templates.where(id: params[:template_id]).first
    if template == nil
      render :json => "Couldn't find template", :status => :unprocessable_entity and return
    end
    template.destroy
    render :json => { _id: params[:template_id] }
  end

  def edit_thing
    thing = @user.things.where(id: params[:thing_id]).first
    old_name = thing.name
    if thing == nil
      render :json => "Couldn't find thing", :status => :unprocessable_entity and return
    end
    if params[:name] == nil
      render :json => "No name!", :status => :unprocessable_entity and return
    end
    thing.update_attribute(:name, params[:name])
    # need to update template too!
    thing_template = @user.thing_templates.where(name: old_name).first
    thing_template.update_attribute(:name, params[:name])

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
end
