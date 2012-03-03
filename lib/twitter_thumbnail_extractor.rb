class TwitterThumbnailExtractor
  
  def self.extract_domain(url)
    return nil if url.nil?
    url.scan(/^http:\/\/(([a-zA-Z0-9\-]+\.?)+)/) do |match|
      return match[0]
    end
    return nil
  end
  
  def self.domain_is_twitterphoto_site?(domain)
     return ["twitpic.com", 'movapic.com', "f.hatena", "moby.to", "yfrog.com", "img.ly", "twitgoo.com", "pic.im", "imgur.com", "tweetphoto.com", "photozou.jp"].include? domain
  end
  
  def self.extract_thumbnails_from_entities(entities)
    ret = []
    return ret if entities.nil? || entities == ''
    entities = JSON.parse(entities)
    return ret if entities.nil?
    
    entities.each_pair do |key, entity|
      if key == 'urls' || key == 'media' then
        if entity then
          entity.each do |url_hash|
            url = url_hash['url']
            t_url = self.extract_thumb(url_hash['expanded_url'])
            if t_url then
              ret.push({:url=>url, :t_url=>t_url})
            end
          end
        end
      end
    end
    return ret.compact
  end
  
  def self.extract_thumb(url)
    thumb = nil
    domain = self.extract_domain(url)
    case domain
      when "twitpic.com"
      thumb = url.gsub(/http:\/\/(?:www\.)?twitpic\.com\/(\w+)/, 'http://twitpic.com/show/thumb/\1')
      when 'movapic.com'
      thumb = url.gsub(/http:\/\/movapic\.com\/pic\/(\w+)/, 'http://image.movapic.com/pic/t_\1.jpeg')
      when "f.hatena"
      thumb = url.gsub(/http:\/\/f\.hatena\.ne\.jp\/(([a-zA-Z])[\w-]{1,30}\w)\/((\d{8})\d+)/,
      'http://img.f.hatena.ne.jp/images/fotolife/\2/\1/\4/\3_120.jpg')
      when "moby.to"
      id = url.gsub("http://#{domain}/", "")
      thumb = "http://#{domain}/#{id}:square"
      when "yfrog.com"
      thumb = url.gsub(/http:\/\/yfrog\.com\/(\w+)/, 'http://yfrog.com/\1:small')
      when "img.ly"
      thumb = url.gsub(/http:\/\/img.ly\/(\w+)/, 'http://img.ly/show/thumb/\1')
      when "twitgoo.com"
      id = url.gsub("http://#{domain}/", "")
      thumb = "http://#{domain}/show/img/#{id}"
      when "pic.im"
      id = url.gsub("http://#{domain}/", "")
      thumb = "http://#{domain}/website/thumbnail/#{id}"
      when "imgur.com"
      id = url.gsub("http://#{domain}/", "").gsub(".jpg", "")
      thumb = "http://i.#{domain}/#{id}l.jpg"
      when "tweetphoto.com"
      thumb = url.gsub(/http:\/\/(?:tweetphoto\.com|pic\.gd)\/\w+/,'http://TweetPhotoAPI.com/api/TPAPI.svc/imagefromurl?size=big&url=\&')
      when "photozou.jp"
      # フォト蔵の場合はフォト蔵APIにサムネイル作成をリクエストし、返ってきたURLを利用する必要あり
      # 2011/2/17時点では未対応
      return nil
    end
    thumb
  end
end