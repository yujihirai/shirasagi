Rails.application.routes.draw do

  Category::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :integration do
    get :split, on: :member
    post :split, on: :member
    get :integrate, on: :member
    post :integrate, on: :member
  end

  content "category" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    resources :nodes, concerns: [:deletion, :integration]
    resources :pages

    get "conf/split" => "node/confs#split"
    post "conf/split" => "node/confs#split"
    get "conf/integrate" => "node/confs#integrate"
    post "conf/integrate" => "node/confs#integrate"
  end

  node "category" do
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "node/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
  end

  part "category" do
    get "node" => "public#index", cell: "parts/node"
  end

end
