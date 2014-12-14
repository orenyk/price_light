require 'lifx'
require 'stock_quote'

module PriceLight

  CHANGE_LIMIT = 0.10
  AVERAGE_VOLUME = 1000000
  VOL_CHANGE_LIMIT = 0.30
  FPS = 20

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
  def evaluate_brightness(volume, avg_vol=AVERAGE_VOLUME)
    vol_change = (volume - avg_vol) / avg_vol
    if vol_change < 0
      brightness = [0.25, 1 - vol_change.abs / VOL_CHANGE_LIMIT].max * 0.5
    elsif vol_change > 0
      brightness = [0.75, vol_change / VOL_CHANGE_LIMIT].min * 0.5
    else
      brightness = 0.5
    end
  end

  # extract scene array from quotes
  def generate_data_arrays(symbol, start_date, end_date)
    # get quotes
    quotes = StockQuote::Stock.history(symbol, start_date, end_date)
    scenes = []

    # process quotes to get data
    quotes.each do |quote|
      # check for valid response
      if quote.response_code == 200
        scene = {}
        scene[:vol] = quote.volume
        scene[:change] = (quote.close - quote.open) / quote.open
        scenes << scene
      end
    end

    # evaluate average
    vol_array = scenes.map { |scene| scene[:vol] }
    avg_vol = vol_array.inject(0.0) { |sum, el| sum + el } / vol_array.size

    data = { scenes: scenes, avg_vol: avg_vol }
  end

  # process scene data and output color
  def set_scene(scene, avg_vol)
    color = evaluate_color(scene[:change])
    color.brightness = evaluate_brightness(scene[:vol], avg_vol)
    color
  end

  # method to loop through a scene array and talk to a bulb
  def process_scenes(light1, data1, light2=nil, data2=nil)
    for i in 0..data1[:scenes].length-1
      light1.set_color(set_scene(data1[:scenes][i], data1[:avg_vol]))
      if light2 && data2
        light2.set_color(set_scene(data2[:scenes][i], data2[:avg_vol]))
      end
      sleep 1
    end
  end

end
