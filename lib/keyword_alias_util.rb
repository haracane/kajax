require 'kconv'
require 'jcode'
require 'nkf'
$KCODE = 'u'

module KeywordAliasUtil
  @@zenkaku_kana = %w(ガ ギ グ ゲ ゴ ザ ジ ズ ゼ ゾ ダ
     ヂ ヅ デ ド バ ビ ブ ベ ボ パ ピ プ ペ ポ ヴ ア イ
     ウ エ オ カ キ ク ケ コ サ シ ス セ ソ タ チ
     ツ テ ト ナ ニ ヌ ネ ノ ハ ヒ フ ヘ ホ マ ミ
     ム メ モ ヤ ユ ヨ ラ リ ル レ
     ロ ワ ヲ ン ャ ュ ョ ァ ィ ゥ ェ ォ ッ
      ゛ ゜).freeze
  @@hankaku_kana = %w(ｶﾞ ｷﾞ ｸﾞ ｹﾞ ｺﾞ ｻﾞ ｼﾞ ｽﾞ ｾﾞ ｿﾞ ﾀﾞ
     ﾁﾞ ﾂﾞ ﾃﾞ ﾄﾞ ﾊﾞ ﾋﾞ ﾌﾞ ﾍﾞ ﾎﾞ ﾊﾟ ﾋﾟ ﾌﾟ ﾍﾟ ﾎﾟ ｳﾞ ｱ ｲ
     ｳ ｴ ｵ ｶ ｷ ｸ ｹ ｺ ｻ ｼ ｽ ｾ ｿ ﾀ ﾁ ﾂ ﾃ ﾄ ﾅ ﾆ ﾇ ﾈ ﾉ
     ﾊ ﾋ ﾌ ﾍ ﾎ ﾏ ﾐ ﾑ ﾒ ﾓ ﾔ ﾕ ﾖ ﾗ ﾘ ﾙ ﾚ ﾛ ﾜ ｦ ﾝ ｬ ｭ
     ｮ ｧ ｨ ｩ ｪ ｫ ｯ ﾞ ﾟ ).freeze

  def self.zenkana_to_hankana(str)
    str = str.clone
    self.filter(str, @@zenkaku_kana, @@hankaku_kana)
  end
  
  def self.normalize_text(keyword)
    keyword = keyword.tr('０-９ａ-ｚＡ-Ｚ', '0-9a-zA-Z').tr('！＃＄％＆＝～｜＾￥＠＋＊；：＜＞？＿、。／', '!#$%&=~|^\\\\@+*;:<>?_,./')
    keyword = keyword.gsub(/[（｛「{\[]/, '(').gsub(/[）｝」}\]]/, ')').gsub(/[\s　]/, '').gsub(/[”’‘“"'`]/, "'").downcase
    #.gsub(/[ー－‐]/, '-')
    keyword = self.filter(keyword, @@hankaku_kana, @@zenkaku_kana)
    keyword = keyword.tr('ャュョァィゥェォ', 'ヤユヨアイウエオ')
  end
  
  def self.filter(str, from, to)
    str = str.clone
    from.each_with_index do |int, i|
      str.gsub!(int, to[i])
    end

    return str
  end

  def self.get_alias_list_from_list(keywordlist)
    ret = []
    keywordlist.each do |keyword|
      get_alias_list(keyword).each do |val|
        ret.push(val)
      end
    end
    return ret
  end

  def self.get_alias_list(keyword)
    keywordList = get_separate_alias(keyword)
    nextKeyList = [];
    keywordList.each do |val|
      get_number_alias(val).each do |val2|
        nextKeyList.push(val2)
      end
    end
    nextKeyList.uniq!

    keywordList = nextKeyList
    nextKeyList = [];
    keywordList.each do |val|
      get_alphabet_alias(val).each do |val2|
        nextKeyList.push(val2)
      end
    end
    nextKeyList.uniq!

    keywordList = nextKeyList
    nextKeyList = [];
    keywordList.each do |val|
      get_ampersand_alias(val).each do |val2|
        nextKeyList.push(val2)
      end
    end
    nextKeyList.uniq!

    keywordList = nextKeyList
    nextKeyList = [];
    keywordList.each do |val|
      get_katakana_alias(val).each do |val2|
        nextKeyList.push(val2)
      end
    end
    nextKeyList.uniq!

    keywordList = nextKeyList
    nextKeyList = [];
    keywordList.each do |val|
      get_hyphen_alias(val).each do |val2|
        nextKeyList.push(val2)
      end
    end
    nextKeyList.uniq!

    return nextKeyList
  end

  def self.get_separate_alias(keyword)
    if keyword =~ /(・)|(　)|\s/ then
      alias_word = keyword.gsub(/(・)|(　)|\s/, '')
      return [keyword, alias_word]
    else
      return [keyword]
    end
  end

  def self.get_ampersand_alias(keyword)
    if keyword =~ /＆/ then
      alias_word = keyword.gsub(/＆/, '&')
      return [keyword, alias_word]
    else
      return [keyword]
    end
  end


  def self.get_number_alias(keyword)
    ret = [keyword]
    if keyword =~ /[0-9]/ then
      ret.push(keyword.tr('0-9', '０-９'))
    end
    if keyword =~ /[０-９]/ then
      ret.push(keyword.tr('０-９', '0-9'))
    end

    return ret
  end

  def self.get_katakana_alias(keyword)
    ret = [keyword]
    if keyword =~ /[ガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポヴアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンャュョァィゥェォッ゛゜ー！]/ then
      ret.push(self.zenkana_to_hankana(keyword))
    end

    return ret
  end

  def self.get_hyphen_alias(keyword)
    ret = [keyword]
    if keyword =~ /-/ then
      ret.push(keyword.gsub(/-/, '―'))
      ret.push(keyword.gsub(/-/, '－'))
    end

    return ret
  end

  def self.get_alphabet_alias(keyword)
    if keyword =~ /[ａ-ｚＡ-Ｚ]/ then
      keyword = keyword.tr('ａ-ｚＡ-Ｚ', 'a-zA-Z')
    end

    ret = [keyword]
    if keyword =~ /[a-zA-Z]/ then
      if keyword =~ /[a-z]/ then
        upper = keyword.upcase
        ret.push(upper)
        ret.push(upper.tr('A-Z', 'Ａ-Ｚ'))
      end
      if keyword =~ /[A-Z]/ then
        down = keyword.downcase
        ret.push(down)
        ret.push(down.tr('a-z', 'ａ-ｚ'))
      end
      ret.push(keyword.tr('a-zA-Z', 'ａ-ｚＡ-Ｚ'))
    end
  #  return ret
    return ret
  end


end