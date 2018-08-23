require 'natto'
require 'twitter'
require './secret.rb'

def tweet2textdata(text)
  replypattern = /@[\w]+/

  text = text.gsub(replypattern, '')
  textURI = URI.extract(text)

  for uri in textURI do
    text = text.gsub!(uri, '')
  end 

  return text
end

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

  # user_nameのツイートを過去tweet_count個取得する
  def get_tweet(user_name, tweet_count)
    tweets = []
    
    @client.user_timeline(user_name, {count: tweet_count, exclude: retweets}).each do |timeline|
      tweet = @client.status(timeline.id)
      if not tweet.text.include?("RT")
        tweets.push(tweet2textdata(tweet.text))
      end
    end

    return tweets
  end

  def search(word, count)
    @client.search(word).take(count).each do |tweet|
      puts tweet.text
    end
  end
end

class NattoParser
  attr_accessor :nm
  
  def initialize()
    @nm = Natto::MeCab.new
  end
  
  def parseTextArray(texts)
    words = []
    index = 0

    for text in texts do
      words.push(Array[])
      @nm.parse(text) do |n|
        if n.surface != ""
          words[index].push(n.surface)
        end
      end
      index += 1
    end

    return words
  end
end

def genMarcovArray(words)
  array = []

  # 最初と最後はnilにする
  words.unshift(nil)
  words.push(nil)

  # 3単語ずつ配列に格納
  for i in 0..words.length-3
    array.push([words[i], words[i+1], words[i+2]])
  end

  return array
end

def main()
  bot = YukiBot.new
  parser = NattoParser.new

  tweets = bot.get_tweet("hsm_hx", 1)
  words = parser.parseTextArray(tweets)
  
  # for word in words
    p genMarcovArray(words[0])
  # end
end

main()
