require 'sinatra'
require 'erb'
require 'twitter'

PANTS = "pants OR jeans OR slacks"

ON = %w(on wearing wear wore worn in)
OFF = %w(off no down without out don't didn't won't)
FLAG = %w(should might had put get back)

helpers do
  def calculate(status)
    parts = status.split(' ')
    parts.delete_if {|x| x.downcase! ; (!ON.include? x and !OFF.include? x and !FLAG.include? x) }
    
    questionable = 0
    on = 0
    off = 0

    parts.each do |x|
      if FLAG.include? x
        questionable += 1
      elsif ON.include? x
        on -= 1
      elsif OFF.include? x
        off += 1
      end
    end

    puts parts
    
    percent = ((on + off).to_f.abs / parts.size.to_f) * 100.0
    variation = (questionable.to_f / parts.size.to_f) * 100.0

    percent = 0 if percent.nan?
    variation = 100 if variation.nan?

    "has a #{percent}% chance of pantslessness with a margin of #{variation}!"
  end

end


get '/' do
  erb :pants
end

post '/search' do
  search = Twitter::Search.new
  search.containing(PANTS).from(params[:username])
  statuses = search.fetch
  
  status = statuses.empty? ? "currently has no data pertaining to pants." : calculate(statuses.first.text)
  @result = "User <a href='http://twitter.com/#{params[:username]}'>@#{params[:username]}</a> #{status}"

  @tweet = statuses.first.text unless statuses.empty?

  erb :status
  
end

