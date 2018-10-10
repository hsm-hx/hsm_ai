require './marcov.rb'

def main()
  keyword = -1

  # ソースを指定して読み込み
  if(ARGV[0] and ARGV[1]) != nil
    dir = "data/" << ARGV[0] << "_" << ARGV[1] << ".json"
  else
    dir = "data/2018_07.json"
  end

  # 会話文を生成
  sentence = generate_text_from_json(keyword, dir)

  p "tweet => " + sentence
end

main()
