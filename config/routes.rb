Habit::Application.routes.draw do

  # things
  post ':user_id/thing/:template_id/create' => 'main#create_thing'
  post ':user_id/thing/:thing_id/destroy' => 'main#destroy_thing'
  post ':user_id/thing/:thing_id/edit' => 'main#edit_thing'

  # templates
  post ':user_id/template/create' => 'main#create_template'
  post ':user_id/template/:template_id/destroy' => 'main#destroy_template'
  post ':user_id/template/:template_id/edit' => 'main#edit_template'

  # misc
  get ':user_id' => 'main#home', :as => :home
  root :to => 'main#create_user'
end
