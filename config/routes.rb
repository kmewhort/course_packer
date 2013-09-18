CoursePacker::Application.routes.draw do
  resources :course_packs do
    resources :articles
    member do
      put :prepare_preview
      get :preview
      get :print_selection
      get :print
    end
  end

  match 'licenses/edit' => 'licenses#edit'

  root to: 'course_packs#create'
end
