Habit::Application.routes.draw do

  post ':user_id/thing/:template_id/create' => 'main#create_thing'
  post ':user_id/thing/:thing_id/destroy' => 'main#destroy_thing'

  post ':user_id/template/:template_id/destroy' => 'main#destroy_template'

  get ':user_id' => 'main#home', :as => :home
  root :to => 'main#create_user'
end
