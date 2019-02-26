require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'open-uri'
require 'json'
require 'net/http'

require 'sinatra/activerecord'
require './models'

require './image_uploader.rb'

enable :sessions

helpers do
  def current_user
    User.find_by(id: session[:user])
  end
end

get '/' do
  @musics = Post.all
  erb :index
end

get '/search' do
  erb :search
end

post '/search' do
  uri = URI("https://itunes.apple.com/search")
  uri.query = URI.encode_www_form({
    term: params[:artist],
    method: "get",
    country: "JP",
    media: "music",
    limit: 20
  })
  res = Net::HTTP.get_response(uri)
  json = JSON.parse(res.body)
  @musics = json['results']
  erb :search
end

post '/new' do
  user = User.find(session[:user])
  music = Post.create(
    artist: params[:artist],
    album: params[:album],
    track: params[:track],
    image_url: params[:image_url],
    sample_url: params[:sample_url],
    comment: params[:comment],
    user_name: user.name,
    user_id: user.id
  )
  redirect '/home'
end

get '/sign_up' do
  erb :sign_up
end

post '/sign_up' do
  @user = User.create(
    name: params[:name],
    img: "https://www.google.com/url?sa=i&source=images&cd=&cad=rja&uact=8&ved=2ahUKEwizos3gtNjgAhXGU7wKHR9_BKAQjRx6BAgBEAU&url=https%3A%2F%2Fhotdog-dachshund.com%2Fillustration-of-a-dog-how-can-i-draw-an-easy-loose-dog-by-handwriting-2898&psig=AOvVaw0F0VKGTHMIHsFmlE07rDT7&ust=1551236562952205",
    password: params[:password]
  )
  if params[:file]
    image_upload(params[:file])
  end
  if @user.persisted?
    session[:user] = @user.id
  end
  redirect '/search'
end

post '/sign_in' do
  user = User.find_by(name:params[:name])
  if user && user.authenticate(params[:password])
    session[:user]=user.id
    redirect '/search'
  else
    redirect '/'
  end
end

get '/sign_out' do
  session[:user] = nil
  redirect '/'
end

before '/home' do
  if current_user.nil?
    redirect '/sign_up'
  end
end

get '/home' do
  @musics = current_user.posts
  erb :home
end

get '/edit/:id' do
  @music = Post.find_by(id:params[:id])
  erb :edit
end

post '/update/:id' do
  music = Post.find_by(id:params[:id])
  music.comment = params[:comment]
  music.save
  redirect '/home'
end

get '/delete/:id' do
  music = Post.find_by(id:params[:id])
  music.destroy
  redirect '/home'
end