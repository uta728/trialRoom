require 'URI'
require 'OPEN-URI'
require 'JSON'

class MojiSlideController < ApplicationController

  # 問題種別
  Q_TYPE = [1, 2]

  #******************************************
  # TOPページ表示
  #******************************************
  def index
  end

  #******************************************
  # スライド画面表示 
  #******************************************
  def slide
    # MojiListテーブルをランダムに並べかえて、最初の１０件を取得 
    mojiList = MojiList.order("RANDOM()").limit(10)
    
    # 問題を作成
    @slideList = []
    mojiList.each_with_index do |moji, idx|
      case Q_TYPE.sample
      when 1
        slide = createQ1(moji)
      when 2
        slide = createQ2(moji)
      end

      @slideList << slide
    end
  end

  #*******************************************
  # 問題を作成（形式１）
  # - 文字を読んで、絵を選択する
  #*******************************************
  def createQ1(moji)
      slide = {}
      slide[:type] = 1

      #slide[:kanji] = moji.kanji
      slide[:yomi] = moji.yomi
      slide[:yomi_v] = moji.yomi.gsub(/ー/,'｜')

      slide[:image] = {}
      slide[:image]["ok"] = getImage(moji)

      dummyMoji = MojiList.where.not(id:moji.id).order("RANDOM()").limit(2)
      dummyMoji.each_with_index do |dMoji, i|
        slide[:image]["ng" + i.to_s] = getImage(dMoji)
      end

      slide[:image_key] = slide[:image].keys
      slide[:image_key].shuffle!

      return slide
  end

  #*******************************************
  # 問題を作成（形式２）
  # - 絵を見て、文字を選択する
  #*******************************************
  def createQ2(moji)
      slide = {}
      slide[:type] = 2

      slide[:image] = getImage(moji)

      slide[:yomi] = {}
      slide[:yomi]["ok"] = {}
      slide[:yomi]["ok"][:yomi] = moji.yomi
      slide[:yomi]["ok"][:yomi_v] = moji.yomi.gsub(/ー/,'｜')

      dummyMoji = MojiList.where.not(id:moji.id).order("RANDOM()").limit(2)
      dummyMoji.each_with_index do |dMoji, i|
        slide[:yomi]["ng" + i.to_s] = {}
        slide[:yomi]["ng" + i.to_s][:yomi] = dMoji.yomi
        slide[:yomi]["ng" + i.to_s][:yomi_v] = dMoji.yomi.gsub(/ー/,'｜')
      end

      slide[:yomi_key] = slide[:yomi].keys
      slide[:yomi_key].shuffle!
      
      return slide
  end

  #******************************************
  # 画像データを取得
  #******************************************
  def getImage(mojiInfo)
    #p mojiInfo.yomi

    # DBにURLが登録されていれば、それを返す
    if !mojiInfo.imgUrl.blank? then
      return mojiInfo.imgUrl
    end

    # Google APIsを使用して画像検索結果をJSON形式で取得
    keyword = mojiInfo.kanji.blank? ? mojiInfo.yomi : mojiInfo.kanji
    page = open(URI.encode("http://ajax.googleapis.com/ajax/services/search/images?q=#{keyword}&v=1.0&hl=ja&rsz=large&start=1&safe=off&referer=https://intense-falls-3023.herokuapp.com/"))
    
    # 1件目のみ使う 
    line = page.gets

    # p "★" + keyword + ":" + line

    # HTTPレスポンスが200以外の場合、なにもしない
   	if JSON[line]['responseStatus'] != 200 then
      return nil
    end if

    # 画像ファイルのURLを取得
		search_result = JSON[line]['responseData']
    urls = []
    if search_result != nil then
      search_result['results'].each do |h| 
        urls << h.values_at('url')
      end
      urls.flatten!
    end

    # DBへURLを登録
    mojiInfo.update(imgUrl: urls[0])

    return urls[0]
  end
end
