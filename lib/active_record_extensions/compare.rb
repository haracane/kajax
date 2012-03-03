module ActiveRecordExtensions
  module Compare
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def compare_cond(compare_sql, val_list)
          return SqlUtil.compare_cond(compare_sql, val_list, {:model=>self})
        end
  
        def compare_or_cond(options={})
          cond_list = options.keys.map { |key|
            self.compare_cond(key, options[key])
          }
          return SqlUtil.or_cond cond_list
        end
        def compare_and_cond(options={})
          cond_list = options.keys.map { |key|
            self.compare_cond(key, options[key])
          }
          return SqlUtil.and_cond cond_list
        end
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::Compare::BaseMethods
end

