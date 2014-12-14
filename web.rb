require 'sinatra'
require "sinatra/reloader" if development?
require 'slim'
require 'pry'

require 'lifx'
require 'stock_quote'

load './price_light.rb'
include PriceLight

get '/' do
  @title = 'Home'
  slim :index, :locals => { title: @title }
end

post '/' do
  binding.pry
  @light_one = params[:light_one]
  redirect to("/#{@light_one}/quote/aapl/2014-01-01/2014-02-01")
end

get '/:light/quote/:symbol/:start_date/:end_date' do
  @title = "#{params[:symbol]} Quote"
  data = generate_data_arrays(params[:symbol], params[:start_date], params[:end_date])
  client = LIFX::Client.lan
  client.discover! { |c| c.lights.count == 3 }
  process_scenes(client.lights.with_label(params[:light]), data)
  slim :quote, :locals => { title: @title, symbol: params[:symbol] }
end