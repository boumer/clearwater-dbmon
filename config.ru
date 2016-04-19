require 'bundler'
Bundler.require

server = Opal::Server.new do |s|
  s.main = 'app'
  s.append_path 'app'
  s.index_path = 'index.html.erb'
end

run server
