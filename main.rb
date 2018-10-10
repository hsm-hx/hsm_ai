require './marcov.rb'

def main()
  bot = TweetBot.new("hsm_ai")
  keyword = -1

  # ソースを指定して読み込み
  if(ARGV[0] and ARGV[1]) != nil
    dir = "data/" << ARGV[0] << "_" << ARGV[1] << ".json"
    generate_text_from_json(keyword, dir)
  else
    generate_text(keyword, bot)
  end

  # 会話文を生成

  p "tweet => " + sentence
  bot.post(sentence)
end

main()
