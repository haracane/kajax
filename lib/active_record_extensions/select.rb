module ActiveRecordExtensions
  module Select
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def select_from(table_name, options={})
          return self.query_by_sql SqlUtil.select_sql(table_name, options)
        end
        
        alias :query_select :select_from
        
        def select_with(options={})
          table_name = options[:table_name] || self.table_name
          return self.select_from(table_name, options)
        end
        
        def select_exist_values(key, value_list, options={})
          key = key.to_s.intern if key.is_a? Symbol
          value_cond = value_list.map{|val| "#{key} = #{self.sanitize val}"}.join(' or ')
          condition_list = []
          condition_list.push SqlUtil.and_cond(options[:conditions]) if options[:conditions]
          condition_list.push value_cond
          return self.select_from(options[:table_name] || self.table_name, :conditions=>condition_list, :select=>key).map{|row| row[key]}
        end
        
        alias :exist_values :select_exist_values
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::Select::BaseMethods
end

