TruestackFuzzinator::Application.routes.draw do
  root :to => "fuzz#index"
  get "/request" => "fuzz#index"
  get "/exception" => "fuzz#exception"
end
