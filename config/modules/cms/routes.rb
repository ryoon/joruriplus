Joruri::Application.routes.draw do
  scp = "admin"
  mod = "cms"
  
  scope "_#{scp}" do
    namespace mod do
      scope :module => scp do
        ## admin
        resources "concepts",
          :controller => "concepts",
          :path => ":parent/concepts" do
            collection do
              get :layouts
              post :layouts
              put :layouts
              delete :layouts
            end
          end
        resources "sites",
          :controller => "sites",
          :path => "sites"
        resources "contents",
          :controller => "contents",
          :path => "contents"
        resources "nodes",
          :controller => "nodes",
          :path => ":parent/nodes" do
            collection do
              get :models
              post :models
              put :models
              delete :models
            end
          end
        resources "layouts",
          :controller => "layouts",
          :path => "layouts"
        resources "pieces",
          :controller => "pieces",
          :path => "pieces" do
            collection do
              get :models
              post :models
              put :models
              delete :models
            end
          end
        resources "data_texts",
          :controller => "data/texts",
          :path => "data_texts"
        resources "data_files",
          :controller => "data/files",
          :path => ":parent/data_files" do
            member do
              get :download
            end
          end
        resources "data_file_nodes",
          :controller => "data/file_nodes",
          :path => ":parent/data_file_nodes"
        resources "inline_data_files",
          :controller => "inline/data_files",
          :path => ":parent/inline_data_files" do
            member do
              get :download
            end
          end
        resources "inline_data_file_nodes",
          :controller => "inline/data_file_nodes",
          :path => ":parent/inline_data_file_nodes"
        resources "kana_dictionaries",
          :controller => "kana_dictionaries",
          :path => "kana_dictionaries" do
            collection do
              get :make, :test
              post :make, :test
              put :make, :test
              delete :make, :test
            end
          end
        resources "navi_concepts",
          :controller => "navi/concepts",
          :path => "navi_concepts"
        
        ## node
        resources "node_directories",
          :controller => "node/directories",
          :path => ":parent/node_directories"
        resources "node_pages",
          :controller => "node/pages",
          :path => ":parent/node_pages"
        resources "node_sitemaps",
          :controller => "node/sitemaps",
          :path => ":parent/node_sitemaps"
        
        ## piece
        resources "piece_frees",
          :controller => "piece/frees",
          :path => "piece_frees"
        resources "piece_page_titles",
          :controller => "piece/page_titles",
          :path => "piece_page_titles"
        resources "piece_bread_crumbs",
          :controller => "piece/bread_crumbs",
          :path => "piece_bread_crumbs"
      end
    end
  end
  
  match "/_admin/#{mod}" => "sys/admin/front#index"
  match "/_admin/#{mod}/tool_rebuild/" => "#{mod}/admin/tool/rebuild#index"
  
  ## public
  match "/_public/#{mod}/node_pages/" => "#{mod}/public/node/pages#index"
  match "/_public/#{mod}/node_sitemaps/" => "#{mod}/public/node/sitemaps#index"

end