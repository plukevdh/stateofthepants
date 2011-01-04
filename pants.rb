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
      if tweet.include?(positive) 
        pos << tweet
      elsif tweet.include?(negative)
        neg << tweet
      else
        tweets.delete tweet
      end
    end

    key = "#{term}:#{positive}:#{negative}"

    # store this result in redis to be updated on future searches
    tweets.each { |x| redis.sadd("tweets:#{key}:total", x) }
    tc = redis.smembers("tweets:#{key}:total").count
    
    pos.each { |x| redis.sadd("tweets:#{key}:positive", x) }
    pc = redis.smembers("tweets:#{key}:positive").count

    neg.each { |x| redis.sadd("tweets:#{key}:negative", x) }
    nc = redis.smembers("tweets:#{key}:negative").count


    redis.set "total:#{key}:count", tc 
    redis.set "positive:#{key}:count", pc 
    redis.set "negative:#{key}:count", nc 

    puts [tc, pc, nc].join ", "
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
  redis.incr "searched:#{params[:term]}:count"

  @total, @positive, @negative = calculate(statuses, params[:term].downcase, params[:positive], params[:negative]) 

  @pcent = (@positive/@total)*100.0
  @ncent = (@negative/@total)*100.0

  erb :status 
end

post '/evaluate' do
  id = params[:id]
  redis.hset :evaluation, params[:term], params[:eval]
end

