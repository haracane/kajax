module PostfixConvert
  module AppendConvertTypeOnIncluded
    def included(base)
      base.extend ClassMethods
      base.append_convert_type self
    end
    module ClassMethods
      attr_accessor :included_convert_types
      
      def self.extended(base)
        #        STDERR.puts "#{self.name} is extended by #{base.name}"
      end
      
      def append_convert_type(converter_class)
        self.included_convert_types ||= []
        convert_type = converter_class.name.split(/::/)[-1].gsub(/Converter/, '').to_snake_case.intern
        #        STDERR.puts convert_type
        self.included_convert_types << convert_type
      end
    end
  end

  module DynamicReturnFirstResultConverter
    def self.included(base)
      base.extend PostfixConvert::AppendConvertTypeOnIncluded::ClassMethods
    end
    
    def return_first_result_convert(method_id, *args, &block)
      convert_type_list = self.class.included_convert_types
      if convert_type_list then
        convert_type_list.each do|convert_type|
          if res = self.send("#{convert_type}_convert", method_id, *args, &block) then
            return res
          end
        end
      end
      return nil
    end
    
    def method_missing(method_id, *args, &block)
      method_name = method_id.to_s
      if res = self.return_first_result_convert(method_id, *args, &block) then
        return res[:result]
      else
        super
      end
    end
  end

  module ByNumberConverter
    extend PostfixConvert::AppendConvertTypeOnIncluded
    def by_number_convert(method_id, *args, &block)
      method_name = method_id.to_s
      if method_name =~ /_by_([0-9]+(\.[0-9]+)?)$/ then
        unit_number = $1.to_f
        f = self.send($`, *args, &block)
        return {:result=>f / unit_number} if f.is_a?(Fixnum) || f.is_a?(Float) && f.finite?
        return {:result=>nil}
      end
      return nil
    end
  end
  
  module ToFormatConverter
    extend PostfixConvert::AppendConvertTypeOnIncluded
    
    def to_format_convert(method_id, *args, &block)
      method_name = method_id.to_s
      if method_name =~ /_(to_[pf][0-9]+)$/ then
        format_convert_method = $1
        f = self.send($`, *args, &block)
        return {:result=>nil} if !f.is_a?(Float) || !f.finite?
        f = f.send format_convert_method
        return {:result=>f}
        f = f * 100 if format_type == 'p'
        

        if f.to_s =~ /(-)?([0-9]+)(\.([0-9]+))?/ then
          sign = $1
          f_a = $2
          f_b = $4
          if !f_b || digit_num <= f_a.length then
            return {:result=>"#{sign}#{f_a}".to_i}
          else
            return {:result=>"#{sign}#{f_a}.#{f_b[0..(digit_num - f_a.length - 1)]}".to_f}
          end
        else
          return {:result=>nil}
        end
      elsif method_name =~ /_to_md$/ then
        d = self.send($`, *args, &block)
        return {:result=>nil} if ! d.is_a?(Date)
        return {:result=>d.strftime('%m/%d')}
      end
      return nil
    end
  end
  
  module XOnYRatioConverter
    extend PostfixConvert::AppendConvertTypeOnIncluded
    def x_on_y_ratio_convert(method_id, *args, &block)
      method_name = method_id.to_s
      if (pair = method_name.split(/_on_/)).size == 2 then
        a = self.send(pair[0])
        b = self.send(pair[1])
        return {:result=>(a.to_f / b.to_f)} if a && b
        return {:result=>nil}
      end
      return nil
    end
  end
end
