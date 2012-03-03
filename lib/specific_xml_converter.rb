# SpecificXmlConverter
module SpecificXmlConverter
  
  def self.text_to_html(text)
    ERB::Util::h(text).gsub(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/, '').gsub(/\n/, '<br/>')
  end
  
  def self.create_tag(key, val)
    return val if ! key
    if key.is_a? Hash then
      tag = key[:tag]
      attributes = key[:attributes]
      tail_tag = tag
    elsif key.is_a? Array then
      tag = key[0]
      attributes = key[1]
      tail_tag = tag
    else
      tag = key
      tail_tag = key.to_s.split(/ +/)[0]
    end

    head_tag = tag
    if attributes then
      if attributes.is_a? Hash then
        attributes_tag = attributes.keys.map{|akey| " #{akey}=\"#{attributes[akey]}\""}.join
      else
        attributes_tag = " #{attributes}"
      end
      head_tag = "#{head_tag}#{attributes_tag}"
    end
    
    if val then
      return "<#{head_tag}>#{val}</#{tail_tag}>"
    else
      return "<#{head_tag}/>"
    end
    
  end
  
  def self.alternate_list_to_xml(elem)
#    STDERR.puts elem.inspect
    return nil if ! elem
    if elem.class == Hash then
      ret = ''
      keys = elem[:_keys] || elem.keys
      keys.each do |key|
        next if key == :_keys
        val = elem[key]
        if val.class == Array || val.class == Hash then
          val = self.alternate_list_to_xml(val)
        elsif val then
          val = self.text_to_html(val)
        end
        
        next_ret = self.create_tag(key, val)
        if ret =~ />$/ && next_ret =~ /^</ then
          next_ret = "\n#{next_ret}"
        end
        ret += next_ret
        
      end
      return ret
    elsif elem.class == Array then
      return nil if elem.size <= 0
      ret = ''
      (elem.size/2).times do |i|
        key = elem[i*2]
        val = elem[i*2+1]
        if val.class == Array || val.class == Hash then
          val = self.alternate_list_to_xml(val)
        else
          val = self.text_to_html(val)
        end
        next_ret = self.create_tag(key, val)
        if ret =~ />$/ && next_ret =~ /^</ then
          next_ret = "\n#{next_ret}"
        end
        ret += next_ret
        
      end
      return ret
    else
      return ERB::Util::h elem
    end
    return nil
  end


  def self.decorate_xml_list(xml_list, decorate_option_list, options={})
    return [] if ! xml_list || xml_list == []
    size = decorate_option_list.size
    if size == 0 then
      return xml_list
    end
  
    next_decorate_option_list = decorate_option_list.slice(1, size - 1)
    decorate_option = decorate_option_list[0];
    
    ret = []
    xml_list.size.times do |i|
      key = xml_list[i*2]
      val = xml_list[i*2+1]
#          STDERR.puts "key=#{key},val=#{val}"
      if val.class == Array then
        rep_val = decorate_xml_list(val, decorate_option_list, options)
        if key then
          ret.push key, rep_val
        else
          ret.push *rep_val
        end
      else
        str = val.to_s
        if str != '' then
          pre_str = nil
          converted_xml_list = nil
          post_str = nil
          decorate_pattern = decorate_option[:pattern]
          case decorate_pattern
          when :enclose_keyword
            keyword = decorate_option[:keyword]
            tag = decorate_option[:tag]
            keyword_len = keyword.length
            if (pos = str.index(keyword)) != nil then
  #            STDERR.puts "[#{keyword}] is found in [#{str}]"
              pre_str = str.slice(0, pos)
              converted_xml_list = [tag, keyword]
              post_str = str.slice(pos + keyword_len, str.length - pos - keyword_len)
            end
          when :http_link
            if str =~ /(http:\/\/(([a-zA-Z0-9\-]+\.?)+)(\/[a-zA-Z0-9%=_\-\?\.&]*)*)/ then
              pre_str = $`
              url = $&
              post_str = $'
              converted_xml_list = [[:a, {:href=>url}], url]
            end
          end
          
          if converted_xml_list then
            ret.push *(decorate_xml_list([nil, pre_str], next_decorate_option_list, options)) if pre_str && pre_str != ''
            ret.push *converted_xml_list
            ret.push *(decorate_xml_list([nil, post_str], decorate_option_list, options)) if post_str && post_str != ''
          else
#            str.gsub!(/\n/, '<br/>')
            ret.push *(decorate_xml_list([key, str], next_decorate_option_list, options))
          end

        end
      end
    end
    return ret

  end

end
