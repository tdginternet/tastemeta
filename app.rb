require 'sinatra'
require 'json'
require 'nokogiri'
require 'open-uri'

require_relative 'config/redis'

before do
  puts '[Params]'
  p params
end

get '/' do
  erb :index
end

post '/' do
  url   = params['url']
  page  = Nokogiri::HTML(open(url))
  metas = page.css("meta[property^=og]")

  content_type :json

  metas.map do |meta|
  	Hash[meta.attributes["property"].value, meta.attributes["content"].value]
  end.to_json
end