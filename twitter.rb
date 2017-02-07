require 'sinatra'
require 'data_mapper'
set :bind, '0.0.0.0'
DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/project.db")
class User
	include DataMapper::Resource
	property :user_id, Serial
	property :email, String
	property :password, String
	property :imagepath,   FilePath
	property :age, Integer
end
class Tweet
	include DataMapper::Resource
	property :tweet_id, Serial
	property :content, String
	property :user_id, Integer
	property :likes, Integer
end
class Followers
    include DataMapper::Resource
	property :follow, Serial
	property :user_id1, Integer
	property :user_id2, Integer
end
class Likes
      include DataMapper::Resource
	property :like, Serial
	property :tweet_id, Integer
	property :user_id, Integer
end

DataMapper.finalize
DataMapper.auto_upgrade!
set :sessions, true
get '/' do 
	if session[:user_id]
		user=User.all(:user_id=>session[:user_id]).first
		tweets=Tweet.all(:user_id=>user.user_id)
			erb :twitterindex, locals: {:user=>user,:tweets=>tweets}
    else
    	erb :twitterlogin, locals:{t:0}
	end
end
get '/login' do
	redirect '/'
end
post '/login' do
		emailid=params[:email]
	user=User.all(:email=>emailid).first
	if user
		if  user.password==params[:password]
			session[:user_id]=user.user_id
			tweets=Tweet.all(:user_id=>user.user_id)
			erb :twitterindex, locals: {:user=>user,:tweets=>tweets}
		else
			erb :twitterlogin, locals:{t:1}
		end

	else
		erb :twitterlogin ,locals:{t:1}
	end
end
get '/signup' do
	erb :twittersignup,locals:{t:0}
end
post '/signup' do
	emailid=params[:email]
	user=User.all(:email=>emailid).first
	if user
		erb :twittersignup, locals:{t:1}
	else
		if params[:age].to_i>=15
		newuser=User.new
		newuser.email=params[:email]
		newuser.password=params[:password]
		newuser.age=params[:age]
		newuser.save
        erb :twittersignup, locals:{t:2}
    else
    	erb :twittersignup, locals:{t:3}
	end

	end
end
get '/logout' do
	session[:user_id]=nil
	redirect '/'
end
post '/tweet' do
	newtweet=Tweet.new
	newtweet.content=params[:tweet]
	newtweet.user_id=session[:user_id]
	newtweet.likes=0
	newtweet.save
	redirect '/'
end
post '/tobefollowed' do
	newfollow=Followers.all(:user_id1=>session[:user_id] ,:user_id2=>params[:tobefollowed]).first
    if newfollow==nil
	newfollow=Followers.new
	newfollow.user_id1=session[:user_id]
	newfollow.user_id2=params[:tobefollowed]
	newfollow.save
else
	newfollow.destroy
    end
	redirect '/'
end
post '/like' do
	if Likes.all(:tweet_id=>params[:tweet_id],:user_id=>session[:user_id]).first==nil
		newlike=Likes.new
		newlike.user_id=session[:user_id]
		newlike.tweet_id=params[:tweet_id]
		tweet=Tweet.all(:tweet_id=>params[:tweet_id]).first	
		tweet.likes=tweet.likes+1
		tweet.save
		newlike.save
	end
	redirect '/'
end
post '/deletetweet' do
	tweet=Tweet.all.first(:tweet_id=>params[:tweet_id])
	tweet.destroy
	like=Likes.all(:tweet_id=>params[:tweet_id])
	if like.first!=nil
	like.destroy
end
redirect '/'
end
post '/imageuploader' do
	user=User.all(:user_id=>session[:user_id]).first
	user.imagepath=params[:pic]
	user.save
	redirect '/'
end
