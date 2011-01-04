require 'sinatra'
require 'erb'
require 'twitter'
require 'redis'

REDIS_CONNECTION = redis = Redis.new(host: "localhost", port: 6379)

helpers do
  def redis
    REDIS_CONNECTION
  end

  def calculate(statuses, term, positive, negative)
    # get texts
    tweets = statuses.map {|x| x.text}
    # delete tweets containing both terms
    pos = []
    neg = []

    tweets.each do |tweet| 
      if tweet.include?(positive) && !tweet.include?(negative)
        pos << tweet
      elsif !tweet.include?(positive) && tweet.include?(negative)
        neg << tweet
      else
        tweets.delete tweet
      end
    end
    
    tc = tweets.count
    nc = neg.count
    pc = pos.count

    # store this result in redis to be updated on future searches
    tweets.each { |x| redis.sadd("tweets:#{term}", tweets) }
    redis.set "total:#{term}:count", tc 
    redis.set "positive:#{term}:count", pc 
    redis.set "negative:#{term}:count", nc 

    return tc.to_f, pc.to_f, nc.to_f
  end
end


get '/' do
  erb :pants
end

post '/search' do
  search = Twitter::Search.new.phrase(params[:term]).containing("#{params[:positive]} OR #{params[:negative]}").per_page(100)
  statuses = search.fetch

  # keep track of search terms
  redis.sadd :searches, params[:term]

  @total, @positive, @negative = calculate(statuses, params[:term].downcase, params[:positive], params[:negative]) 

  @pcent = (@positive/@total)*100.0
  @ncent = (@negative/@total)*100.0

  erb :status 
end

post '/evaluate' do
  id = params[:id]
  redis.hset :evaluation, params[:term], params[:eval]
end

