
module DbEscape
  def self.db_unescape(text)
    if text == nil || text == '\\N' then
      return nil
    else
      rest = text
      ret = ''
      escape_flag = false
      while rest =~ /\\(.)/ do
        escape_flag = true
        ret += $`
        code = $1
        rest = $'
        case code
        when '\\'
          ret += '\\'
        when 'a'
          ret += "\a"
        when 'b'
          ret += "\b"
        when 'n'
          ret += "\n"
        when 'r'
          ret += "\r"
        when 't'
          ret += "\t"
        end
      end
      if escape_flag then
        return ret + rest
      else
        return text
      end
    end
  end

  def self.db_escape(text)
    if text == nil then
      return '\\N'
    end
    rest = text
    ret = ''
    escape_flag = false
    while rest =~ /[\\\a\b\n\r\t]/ do
      escape_flag = true
      ret += $`
      code = $&
      rest = $'
      case code
      when '\\'
        ret += '\\\\'
      when "\a"
        ret += "\\a"
      when "\b"
        ret += "\\b"
      when "\n"
        ret += "\\n"
      when "\r"
        ret += "\\r"
      when "\t"
        ret += "\\t"
      end
    end
    if escape_flag then
      return ret + rest
    else
      return text
    end
  end

  def self.db_escape_test
    text = "1\a2\b3\n4\r5\t6"
    escape_text = DbEscape.db_escape(text)
    restore_text = DbEscape.db_unescape(escape_text)
    puts text
    puts escape_text
    puts restore_text
  end
end
