require 'sinatra'
require 'slim'
require 'pry'

require 'hue'
require 'stock_quote'

get '/' do
  @title = 'Home'
  slim :index, :locals => { title: @title }
end