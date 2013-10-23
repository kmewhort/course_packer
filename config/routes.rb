CoursePacker::Application.routes.draw do
  resources :course_packs do
    resources :articles
    member do
      put :prepare_preview
      get :preview
      get :print_selection
      get :print
      get :share_selection
    end
  end

  devise_for :users

  match 'licenses/edit' => 'licenses#edit'

  # static pages
  root to: 'static_pages#home'
end
