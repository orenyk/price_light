require 'lifx'
require 'stock_quote'

module PriceLight

  CHANGE_LIMIT = 0.10
  AVERAGE_VOLUME = 1000000
  VOL_CHANGE_LIMIT = 0.30

  # extract color from relative change in stock price
  def evaluate_color(change)
    # for a loss, give a shade of red
    if change < 0
      change = [-change, CHANGE_LIMIT].min
      color = LIFX::Color.rgb(255*change/CHANGE_LIMIT, 0, 0)
    # for a gain, give a shade of green
    elsif change > 0
      change = [change, CHANGE_LIMIT].min
      color = LIFX::Color.rgb(0, 255*change/CHANGE_LIMIT, 0)
    # otherwise (e.g. no change), give white
    else
      color = LIFX::Color.rgb(255, 255, 255)
    end
  end

  # evaluate brightness from volume relative to average volume over last three
  # months (average = 0.5)
  def evaluate_brightness(volume, average_volume=AVERAGE_VOLUME)
    vol_change = (volume - average_volume) / average_volume
    if vol_change < 0
      brightness = [0, 1 - vol_change.abs / VOL_CHANGE_LIMIT].max * 0.5
    elsif vol_change > 0
      brightness = [1, vol_change / VOL_CHANGE_LIMIT].min * 0.5
    else
      brightness = 0.5
    end
  end

  def generate_data_arrays(symbol, start_date, end_date)
    quote = StockQuote::Stock.history(symbol, start_date, end_date)
    vol_array = quote.map(&:volume)
    avg_volume = vol_array.inject(0.0) { |sum, el| sum + el } / vol_array.size
    change_array = quote.map { |q| (q.close - q.open) / q.open }
