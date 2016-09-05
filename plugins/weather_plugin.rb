# encoding: utf-8
require 'wunderground'
require './config.rb'

class WeatherUser < Sequel::Model(DB[:weather])
  unrestrict_primary_key
end

class WeatherPlugin
  include Cinch::Plugin

  self.prefix = '.'


  match /w register (.*)/,     method: :register, group: :weathergroup
  match /w ([^\s]+)/,          method: :weather, group: :weathergroup
  match /w/,                   method: :registered_weather, group: :weathergroup

  match /template(\s[^\s].*)/, method: :help




  def initialize(*args)
    @w_api = Wunderground.new(CONFIG['wunderground_api_key'])
    super
  end

  def weather(m, city)
    m.reply parse_weather_simple weather_query(city)
  end

  def register m, location
    user = WeatherUser.find(:nick => m.user.nick)
    user ||= WeatherUser.create(:nick => m.user.nick, :weather_string => location)
    user.weather_string = location
    user.save
    m.reply "Done."
  end

  def registered_weather(m)
    user_location = WeatherUser[m.user.nick]
    if user_location.nil?
      m.reply "No location registered for #{m.user.nick}"
      return
    end
    m.reply parse_weather_simple weather_query(user_location[:weather_string])
  end

  def weather_query(q)
    query = @w_api.conditions_for(q).to_s
    h = eval(query)
  end

  def parse_weather_simple h
    location = h["current_observation"]["display_location"]["full"].to_s
    conditions = h["current_observation"]["weather"].to_s
    temp = h["current_observation"]["temp_c"].to_s
    "#{h["current_observation"]["display_location"]["full"].to_s}: #{conditions} and #{temp}°C"
  end



  def help(m)
    m.channel.send '.w [city] to get weather for a city'
  end
end