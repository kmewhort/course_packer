# pull code from github repo
set :application, "course_packer"
set :repository,  "git@github.com:kmewhort/course_packer.git"
set :branch, "master"
set :scm, "git"
set :ssh_options, { :forward_agent => true }

# single-server deployment at course
role :web, "coursepacker.org"
role :app, "coursepacker.org"
role :db,  "coursepacker.org"
default_run_options[:pty] = true
set :user, "kent"
set :deploy_via, :remote_cache
set :deploy_to, "/var/www/course_packer"

# keep the file uploads shared between deployments
set :shared_children, %w{public/system log tmp/pids public/article public/course_pack public/license public/uploads}

# use bundler
require "bundler/capistrano"

# cleanup each deploy
after "deploy:restart", "deploy:cleanup"

# restart Passenger
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end