require 'sinatra'
require "sinatra/reloader" if development?
require 'slim'
require 'pry'

require 'lifx'
require 'stock_quote'

load './lib/price_light_lifx.rb'
include PriceLightLifx

get '/' do
  @title = 'Home'
  slim :index, :locals => { title: @title }
end

post '/' do
  @light_one = params[:light_one]
  @symbol_one = params[:symbol_one]
  @light_two = params[:light_two]
  @symbol_two = params[:symbol_two]
  @start_date = params[:start_date]
  @end_date = params[:end_date]
  data1 = generate_data_arrays(@symbol_one, @start_date, @end_date)
  data2 = generate_data_arrays(@symbol_two, @start_date, @end_date)
  client = LIFX::Client.lan
  unless @light_two.nil?
    client.discover! { |c| c.lights.count == 2}
  else
    client.discover!
  end
  process_scenes(
    client.lights.with_label(@light_one), data1,
    client.lights.with_label(@light_two), data2)
  redirect to("/quote")
end

get '/quote' do
  @title = "Price Light"
  slim :quotes, :locals => { title: @title }
end

get '/:light/quote/:symbol/:start_date/:end_date' do
  @title = "#{params[:symbol]} Quote"
  data = generate_data_arrays(params[:symbol], params[:start_date], params[:end_date])
  client = LIFX::Client.lan
  client.discover! { |c| c.lights.count == 3 }
  process_scenes(client.lights.with_label(params[:light]), data)
  slim :quote, :locals => { title: @title, symbol: params[:symbol] }
end

# TODO write form and view
get '/menorah' do
  @title = 'Menorah'
  slim :menorah, :locals => { title: @title }
end

post '/menorah' do
  client = LIFX::Client.lan
  client.discover! { |c| c.lights.count == 8 }
  for i in 1..8 do
    client.lights.with_label("menorah#{i}").set_color(LIFX::Color.rgb(255, 102, 0)) if params["menorah#{i}".to_sym] == 1
  end
end