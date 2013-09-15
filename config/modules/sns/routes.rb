# -*- encoding: utf-8 -*-
Joruri::Application.routes.draw do
  mod = "sns"
  scp = "admin"

  scope "_#{scp}" do
    namespace mod do
      scope :module => scp do
        resources :profiles
        resources :profile_configs do
          collection do
            post :message
          end
        end
        resources :offices
        resources :profile_photos do
          member do
            get :select
          end
        end
        resources :profile_photo_selects do
          collection do
            post :upload
            get :crop
          end
        end
        resources :privacies
        resources :custom_groups do
          collection do
            get :group_field, :user_field
          end
        end
        resources :message_boards do
          member do
            post :update_message
          end
        end
        resources :notices
        resources :activity_configs
        resources :notes
        resources :notes_comments, :path=>"notes/:parent/comments", :controller=>"notes/comments" do
          member do
            get :delete
          end
        end
        resources :searches do
          collection do
            get :group_field
          end
        end
        resources :friend_proposals do
          member do
            get :recognize, :refuse
            post :reply
          end
          collection do
            get :package_proposal, :recognize_all
            post :do_proposal, :package_recognize, :reply_all
          end
        end
        resources :friends do
          member do
            get :remove
          end
        end
        resources :uploads
        resources :likes do
          member do
            get :delete,:show_comment, :comment, :delete_comment
          end
        end
        resources :favorites do
          member do
            get :delete
          end
        end
        resources :user_photos, :path=>"profiles/:account/photos", :controller=>"profiles/photos"
        resources :albums
        resources :user_files, :path=>"profiles/:account/files" , :controller=>"profiles/files"
        resources :user_notes, :path=>"profiles/:account/notes", :controller=>"profiles/notes"
        resources :user_videos, :path=>"profiles/:account/videos", :controller=>"profiles/videos"
        resources :presences, :controller=>"profiles/presences" do
          collection do
            get :set,:project, :stack
          end
        end
        resources :videos do
          member do
            get :player
          end
        end
        resources :photos do
          member do
            get :download, :down
          end
        end
        resources :files do
          member do
            get :download, :down
            post :upload
          end
        end
        resources :posts do
          collection do
            get :list, :refresh, :cat_ind, :users_field,:group_field
          end
          member do
            get :delete,:publish, :select_user, :published_user, :show_photos
            post :set_user
          end
        end
        resources :items
        resources :comments, :path=>":parent/comments" do
          member do
            get :delete
          end
        end
        resources :enquetes, :path=>":parent/enquetes"
        resources :projects
        resources :conferences, :path=>"projects/:parent/conferences", :controller=>"projects/conferences" do
          member do
            #delete :destroy_res
            get :edit_res,:delete_res,:delete
            put :update_res
          end
          collection do
            post :reply
            get :attach
          end
        end
        resources :members, :path=>"projects/:parent/members", :controller=>"projects/members" do
          member do
            get :approval
          end
          collection do
            get :proposal, :users_field,:group_field
            post :invite
          end
        end
        resources :proposals, :path=>"projects/:parent/proposals", :controller=>"projects/proposals" do
          collection do
            get :motion
          end
        end
        resources :histories, :path=>"projects/:parent/histories", :controller=>"projects/histories"
        resources :reports, :path=>"projects/:parent/reports", :controller=>"projects/reports"
        resources :schedules, :path=>"projects/:parent/schedules", :controller=>"projects/schedules" do
          member do
            get :join
          end
          collection do
            get :daily
          end
        end
        resources :project_photos, :path=>"projects/:parent/photos", :controller=>"projects/photos"
        resources :project_files, :path=>"projects/:parent/files", :controller=>"projects/files"
        resources :project_videos, :path=>"projects/:parent/videos", :controller=>"projects/videos"
        resources :managers
        resources :profile_informations, :controller=>"managers/informations" do
          collection do
            get :group_field
          end
        end
        resources :display_items, :controller=>"managers/display_items" do
          collection do
            get :group_field
          end
        end
        resources :sample_photos, :controller=>"managers/sample_photos" do
          member do
            get :crop
          end
        end
        resources :photo_counts, :controller=>"managers/photo_counts" do
          collection do
            get :posts
          end
        end
        resources :sys_addresses do
          member do
            get :child_groups, :child_users, :child_items
          end
          collection do
            post :mobile_manage
          end
        end
      end
    end
  end

end
