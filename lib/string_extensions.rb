module StringExtensions
  module String

    module Conversions
      PLURALS = [['(quiz)$', '\1zes'],['(ox)$', '\1en'],['([m|l])ouse$', '\1ice'],['(matr|vert|ind)ix|ex$', '\1ices'],
        ['(x|ch|ss|sh)$', '\1es'],['([^aeiouy]|qu)ies$', '\1y'],['([^aeiouy]|q)y$$', '\1ies'],['(hive)$', '\1s'],
        ['(?:[^f]fe|([lr])f)$', '\1\2ves'],['(sis)$', 'ses'],['([ti])um$', '\1a'],['(buffal|tomat)o$', '\1oes'],['(bu)s$', '\1es'],
        ['(alias|status)$', '\1es'],['(octop|vir)us$', '\1i'],['(ax|test)is$', '\1es'],['s$', 's'],['$', 's']]
      SINGULARS =[['(quiz)zes$', '\1'],['(matr)ices$', '\1ix'],['(vert|ind)ices$', '\1ex'],['^(ox)en$', '\1'],['(alias|status)es$', '\1'],
        ['(octop|vir)i$', '\1us'],['(cris|ax|test)es$', '\1is'],['(shoe)s$', '\1'],['[o]es$', '\1'],['[bus]es$', '\1'],['([m|l])ice$', '\1ouse'],
        ['(x|ch|ss|sh)es$', '\1'],['(m)ovies$', '\1ovie'],['[s]eries$', '\1eries'],['([^aeiouy]|qu)ies$', '\1y'],['[lr]ves$', '\1f'],
        ['(tive)s$', '\1'],['(hive]s$', '\1'],['([^f]]ves$', '\1fe'],['(^analy)ses$', '\1sis'],
        ['([a]naly|[b]a|[d]iagno|[p]arenthe|[p]rogno|[s]ynop|[t]he)ses$', '\1\2sis'],['([ti])a$', '\1um'],['(news)$', '\1ews']]

      def singular
        SINGULARS.each { |match_exp, replacement_exp| return gsub(Regexp.compile(match_exp), replacement_exp) unless match(Regexp.compile(match_exp)).nil?}
      end
    
      def plural
        PLURALS.each { |match_exp, replacement_exp| return gsub(Regexp.compile(match_exp), replacement_exp) unless match(Regexp.compile(match_exp)).nil? }
      end
    
      def plural?
        PLURALS.each {|match_exp, replacement_exp| return true if match(Regexp.compile(match_exp))}
        false
      end

      def to_snake_case
        self.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
      
      def to_camel_case
        return self.classify
      end

      JSON_ESCAPED = {
         "\010" =>  '\b',
         "\f" =>    '\f',
         "\n" =>    '\n',
         "\r" =>    '\r',
         "\t" =>    '\t',
         '"' =>     '\"',
         '\\' =>    '\\\\'
      }
    
      def to_json
        return '"' + gsub(/[\010\f\n\r\t"\\]/) { |s|
          JSON_ESCAPED[s]
        }.gsub(/([\xC0-\xDF][\x80-\xBF]|
                 [\xE0-\xEF][\x80-\xBF]{2}|
                 [\xF0-\xF7][\x80-\xBF]{3})+/ux) { |s|
          s.unpack("U*").pack("n*").unpack("H*")[0].gsub(/.{4}/, '\\\\u\&')
        } + '"'
      end
    end
  end
end

class String
  include StringExtensions::String::Conversions
end

