module ActiveRecordExtensions
  module Count
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def count_from(table_name, options={})
          res = self.query_by_sql SqlUtil.count_sql(table_name, options)
          return nil if ! res || res.size == 0
          return res[0][:count].to_i
        end
  
        alias :query_count :count_from
        def count_with(options={})
          table_name = options[:table_name] || self.table_name
          return self.count_from(table_name, options)
        end
        
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::Count::BaseMethods
end

