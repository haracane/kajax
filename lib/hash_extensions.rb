module HashExtensions
  module Hash
    module MultiDimensionAccess
      def fetch_with_keys(key_list)
        ret = self
        key_list.each do |key|
          ret = ret[key]
          return nil if ret == nil
        end
        return ret
      end
      
      def store_with_keys(key_list, val)
        last_index = key_list.size - 1
        target_hash = self
        key_list.each_index do |i|
          key = key_list[i]
          if i == last_index then
            target_hash[key] = val
          else
            target_hash = (target_hash[key] ||= {})
          end
        end
        #    puts "store [#{key_list.join(', ')}], #{self.fetch_with_keys key_list}"
        return val
      end
    end
  end
end

class Hash
  include HashExtensions::Hash::MultiDimensionAccess
end
