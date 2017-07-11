require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require 'nokogiri'
require 'open-uri'
require "digest/md5"
require 'browser'

require_relative 'config/redis'

register Sinatra::CrossOrigin

configure do
  enable :cross_origin
end

get '/' do
  erb :index
end

post '/' do
  url   = params['url']
  page  = Nokogiri::HTML(open(url))
  metas = page.css("meta[property^=og]")

  metas = metas.map do |meta|
  	Hash[meta.attributes["property"].value, meta.attributes["content"].value]
  end.to_json

  shortened_id = $redis.incr("urls._id").to_s(36)
  $redis.hset("tastemeta:#{shortened_id}", url, metas)

  redirect "/#{shortened_id}?inspect"
end

get '/:shortened_id' do
  shortened_id = params['shortened_id']
  results = $redis.hgetall("tastemeta:#{shortened_id}")

  @metas = JSON.parse(results.values.first)
  @origin_url = results.keys.first

  if browser.bot?
    erb :page
  elsif params.key?('inspect')
    erb :inspect
  else
    redirect @origin_url
  end
end

post '/:shortened_id' do
  shortened_id = params['shortened_id']
  metas        = params['metas']
  url          = params['origin_url']

  # convert to array of hashes
  metas = metas.map{|meta| Hash[*meta]}.to_json

  $redis.hset("tastemeta:#{shortened_id}", url, metas)

  redirect "/#{shortened_id}?inspect"
end

private

def browser
  @_browser ||= Browser.new(request.user_agent)
end
