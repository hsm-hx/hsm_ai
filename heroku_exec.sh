/app/vendor/mecab/libexec/mecab/mecab-dict-index \
  -d /app/vendor/mecab/lib/mecab/dic/ipadic \
  -u user.dic \
  -f utf-8 -t utf-8 user.csv

mv user.dic /app/vendor/mecab/lib/mecab/dic/ipadic/

echo "userdic = /app/vendor/mecab/dic/ipadic/user.dic" >> /app/vendor/mecab/lib/mecab/dic/ipadic/dicrc

find /app/vendor/ -name "*mecab*"

ruby bot.rb
