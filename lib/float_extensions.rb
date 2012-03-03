module FloatExtensions
  module Float
    module Conversions
      def self.format_convert(f, format_type, digit_num)
        f = f * 100 if format_type == 'p'

        if f.to_s =~ /(-)?([0-9]+)(\.([0-9]+))?/ then
          sign = $1
          f_a = $2
          f_b = $4
          if !f_b || digit_num <= f_a.length then
            return "#{sign}#{f_a}".to_f
          else
            return "#{sign}#{f_a}.#{f_b[0..(digit_num - f_a.length - 1)]}".to_f
          end
        end
        return nil
      end
    end
  end
end

class Float
  def method_missing(method_id, *args, &block)
    method_id = method_id.to_s
    if method_id =~ /^to_([fp])(\d+)$/ then
      return ExtendPatch::CoreExtensions::Float::Conversions.format_convert(self, $1, $2.to_i)
    else
      return super
    end
  end
end
