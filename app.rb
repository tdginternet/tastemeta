require 'browser'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'sinatra'

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

get '/:shortened' do
  if browser.bot?
    erb :page
  else
    content_type :json
    params.to_json
  end
end

private

def browser
  @_browser ||= Browser.new(request.user_agent)
end