module ActiveRecordExtensions
  module Conversions
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      def to_hash
        ret = {}
        self.attribute_names.each do |key|
          ret[key.intern] = self[key]
        end
        return ret
      end
  
      def values_at(*key_list)
        return key_list.map{|key| self[key]}
      end
      
      module ClassMethods
        def type_cast_and_new(record)
          ret = self.new
          record.keys.each do |key|
            val = record[key]
            column = ret.column_for_attribute(key)
            if val && column then
              ret[key] = column.type_cast val
              #                  STDERR.puts "#{record[key]} -> #{ret[key]}"
            end
          end
          return ret
        end
        
        def create_hash_by(attribute_names, record_list)
          attribute_ids = attribute_names.map{|attribute_name| attribute_name.to_sym}
          ret = {}
          record_list.each do |record|
            ret.store_with_keys(record.values_at(*attribute_ids).map, record)
          end
          return ret
        end
        
        def sql_value(val)
          return SqlUtil.sql_value(val, {:model=>self})
        end
  
        def values_sql(keys, record)
          keys.map{|key| 
            val = record[key]
            if val == true then
              val = 1
            elsif val == false then
              val = 0
            end
            self.sanitize(val)
          }.join(', ')
        end
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::Conversions::BaseMethods
end

