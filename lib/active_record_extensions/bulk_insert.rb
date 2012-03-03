module ActiveRecordExtensions
  module BulkInsert
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def insert_values_in_bulk(records, options={})
          return self.insert_in_bulk_into(self.table_name, records, options)
        end
        
        def insert_in_bulk_into(table_name, records, options={})
          options[:ignore_exception] = true if options[:ignore_exception] == nil
          return 0 if records == []
          columns = self.insert_column_keys(options)
          
          insert_into_sql = "insert into #{table_name} (#{columns.join(', ')})"
          
          values_sql = records.map { |record|
            <<-EOF
            (#{self.values_sql(columns, record)})
            EOF
          }.join(', ')
          begin
            self.connection.select_all <<-EOF
              #{insert_into_sql}
              values #{values_sql};
            EOF
            count = records.size
            self.logger.info Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO) insert #{count} records into #{table_name} in bulk")
          rescue Exception=> e
            if options[:ignore_exception] then
              self.logger.info Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO) Exception: #{e}")
              count = self.insert_into(table_name, records, options)
            else
              raise e
            end
          end
          return count
        end
      
        def insert_values_in_bulks(records, options={})
          return self.insert_in_bulks_into(self.table_name, records, options)
        end
        
        def insert_in_bulks_into(table_name, records, options={})
          count = 0
          bulk_size = options[:bulk_size] || 100
          unique_key = options[:unique_key]
          
          if bulk_size == 1 then
            return self.insert_into(table_name, records, options)
          else
            offset = 0
            while offset < records.size do
              i_records = records[offset, bulk_size]
              offset += bulk_size
              self.delete_exist_records(unique_key, i_records) if unique_key
              
              count += self.insert_in_bulk_into(table_name, i_records, options)
            end
            return count
          end
        end
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::BulkInsert::BaseMethods
end

