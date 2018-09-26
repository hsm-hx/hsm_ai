require 'natto'
require 'twitter'

class TweetBot
  attr_accessor :client
  attr_accessor :screen_name

  public
    def initialize(screen_name)
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key = ENV['CONSUMER_KEY']
        config.consumer_secret = ENV['CONSUMER_SECRET']
        config.access_token = ENV['ACCESS_TOKEN_KEY']
        config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
      end
  
      @screen_name = screen_name
    end
     
    def post(text = "", twitter_id:nil, status_id:nil)
      if status_id
        rep_text = "@#{twitter_id} #{text}"
        @client.update(rep_text, {:in_reply_to_status_id => status_id})
      else
        @client.update(text)
      end
    end
    
    def get_tweet(count=15, user=@screen_name)
      tweets = []
      
      @client.user_timeline(user, {count: count}).each do |timeline|
        tweet = @client.status(timeline.id)
        # RT(とRTを含むツイート)を除外
        if not (tweet.text.include?("RT"))
          # Deckと泥公式以外からのツイートを除外
          if (tweet.source.include?("TweetDeck") or
              tweet.source.include?("Twitter for Android"))
            tweets.push(tweet2textdata(tweet.text))
          end
        end
      end

      return tweets
    end
    
    def auto_follow()
      begin
        @client.follow(
          get_follower(@screen_name) - get_friend(@screen_name)
        )
      rescue Twitter::Error::Forbidden => error
        # そのまま続ける
        p error
      end  
    end
    
  private
    # ===============================================
    # Twitter API
    # ===============================================
    def fav(status_id)
      if status_id
        @client.favorite(status_id)
      end
    end
    
    def retweets(status_id:nil)
      if status_id
        @client.retweet(status_id)
      end
    end
    
    def search(word, count=15)
      tweets = []
      @client.search(word).take(count).each do |tweet|
        tweets.push(tweet.id)
      end
      return tweets
    end
    
    def get_follower(user=@screen_name)
      follower = []
      @client.follower_ids(user).each do |id|
        follower.push(id)
      end
      return follower
    end
    
    def get_friend(user=@screen_name)
      friend = []
      @client.friend_ids(user).each do |id|
        friend.push(id)
      end
      return friend
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
      # 単語数を数える
      count_noun = 0
      @nm.parse(text) do |n|
        count_noun += 1
      end

      # 1単語しかなければ以後の処理を行わない
      if count_noun == 1
        break
      end

      words.push(Array[])
      @nm.parse(text) do |n|
        if n.surface != ""
          words[index].push([n.surface, n.posid])
        end
      end
      index += 1
    end

    return words
  end
end

class Marcov
  public
    def marcov(array)
      result = []
      block = []

      block = findBlocks(array, -1)
      begin
        result = connectBlocks(block, result)
        if result == -1
          raise RuntimeError
        end
      rescue RuntimeError
        retry
      end
     
      # resultの最後の単語が-1になるまで繰り返す
      while result[result.length-1] != -1 do
        block = findBlocks(array, result[result.length-1])
        begin
          result = connectBlocks(block, result)
          if result == -1
            raise RuntimeError
          end
        rescue RuntimeError
          return -1
        end
      end
      
      return result
    end

    def genMarcovBlock(words)
      array = []

      # 最初と最後は-1にする
      words.unshift(-1)
      words.push(-1)

      # 3単語ずつ配列に格納
      for i in 0..words.length-3
        array.push([words[i], words[i+1], words[i+2]])
      end

      return array
    end

  private
    def findBlocks(array, target)
      blocks = []
      for block in array
        if block[0] == target
          blocks.push(block)
        end
      end
      
      return blocks
    end

    def connectBlocks(array, dist)
      i = 0
      begin
        for word in array[rand(array.length)]
          if i != 0
            dist.push(word)
          end
          i += 1
        end
      rescue NoMethodError
        return -1
      else
        return dist
      end
    end
end

# ===================================================
# 汎用関数
# ===================================================
def generate_text(bot, screen_name=nil, dir=nil)
  parser = NattoParser.new
  marcov = Marcov.new

  block = []

  tweet = ""
  
  if not screen_name == nil
    tweets = bot.get_tweet(200, screen_name)
  elsif not dir == nil
    tweets = get_tweets_from_JSON(dir)
  else
    raise RuntimeError
  end

  words = parser.parseTextArray(tweets)
  
  # 3単語ブロックをツイートごとの配列に格納
  for word in words
    block.push(marcov.genMarcovBlock(word))
  end

  block = reduce_degree(block)

  # 140字に収まる文章が練成できるまでマルコフ連鎖する
  while tweet.length == 0 or tweet.length > 140 do
    begin
      tweetwords = marcov.marcov(block)
      if tweetwords == -1
        raise RuntimeError
      end
    rescue RuntimeError
      retry
    end
    tweet = words2str(tweetwords)
  end
  
  return tweet
end

def get_tweets_from_JSON(filename)
  data = nil

  File.open(filename) do |f|
    data = JSON.load(f)
  end

  tweets = []

  for d in data do
    if d["user"]["screen_name"] == "hsm_hx"
      if d["retweeted_status"] == nil
        tweets.push(tweet2textdata(d["text"]))
      end
    end
  end

  return tweets
end

def words2str(words)
  str = ""
  for word in words do
    if word != -1
      str += word[0]
    end
  end
  return str
end

def reduce_degree(array)
  result = []

  array.each do |a|
    a.each do |v|
      result.push(v)
    end
  end
  
  return result
end

def tweet2textdata(text)
  replypattern = /@[\w]+/

  text = text.gsub(replypattern, '')

  textURI = URI.extract(text)

  for uri in textURI do
    text = text.gsub(uri, '')
  end 

  return text
end
# ===================================================
# MAIN
# ===================================================
def main()
  bot = TweetBot.new("hsm_ai")
  
  tweet_source = "hsm_hx"

  if (ARGV[0] and ARGV[1]) != nil
    dir = "data/" << ARGV[0] << "_" << ARGV[1] << ".json"
    tweet = generate_text(bot, nil, dir)
  else
    tweet = generate_text(bot, tweet_source)
  end

  p tweet
  bot.post(tweet)
  
  bot.auto_follow()
end

main()
