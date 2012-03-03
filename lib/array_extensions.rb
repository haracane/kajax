
module ArrayExtensions
  module Array
    module Conversions
      def to_hash_with_key(&block)
        ret = {}
        self.each do |val|
          ret[yield(val)] = val
        end
        return ret
      end
      
      def to_pairs
        ret = []
        (self.size/2).times do |i|
          ret.push [self[i*2], self[i*2+1]]
        end
        return ret
      end

      def map_concat(&block)
        self.map(&block).flatten(1)
      end
      
      def is_all_valid(&block)
        self.each do |val|
          return false if ! val
        end
        return true
      end
      
      def is_all_invalid(&block)
        self.each do |val|
          return false if val
        end
        return true
      end

      def has_valid(&block)
        self.each do |val|
          return true if val
        end
        return false
      end
      
      def has_invalid(&block)
        self.each do |val|
          return true if ! val
        end
        return false
      end
    end
    module Filters
      def select_by_condition(&block)
        ret = []
        self.each do |val|
          ret.push val if yield(val)
        end
        return ret
      end
    end
  end
end


class Array
  include ArrayExtensions::Array::Conversions
  include ArrayExtensions::Array::Filters
end
