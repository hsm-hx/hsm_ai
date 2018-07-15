require 'twitter'
require './secret.rb'

class YukiBot
  attr_accessor :client

  def initialize
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key = CONSUMER_KEY
      config.consumer_secret = CONSUMER_SECRET
      config.access_token= OAUTH_TOKEN
      config.access_token_secret= OAUTH_SECRET
    end
  end

  def post(text = "", twitter_id:nil, status_id:nil)
    if status_id
      rep_text = "@#{twitter_id} #{text}"
      @client.update(rep_text, {:in_reply_to_status_id => status_id})
      puts "#{text}"
    else
      @client.update(text)
      puts "#{text}"
    end
  end

  def fav(status_id:nil)
    if status_id
      @client.favorite(status_id)
    end
  end

  def retweets(status_id:nil)
    if status_id
      @client.retweet(status_id)
    end
  end

  def show_recently_tweet(user_name, tweet_count)
    @client.user_timeline(user_name, {count: tweet_count}).each do |timeline|
      tweet = @client.status(timeline.id)
      puts tweet.created_at
      puts tweet.text
    end
  end

  def search(word, count)
    @client.search(word).take(count).each do |tweet|
      puts tweet.text
    end
  end
end

bot = YukiBot.new

bot.search("#はすみめも", 5)
