module ActiveRecordExtensions
  module Insert
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def insert_column_keys(options={})
          ret = self.column_names
          ret.delete('id') if ! options[:insert_id]
          return ret.map(&:intern)
        end
        
        def insert_values(records, options={})
          self.insert_into(self.table_name, records, options)
        end
        
        def insert_into(table_name, records, options={})
          options[:ignore_exception] = true if options[:ignore_exception] == nil
          count = 0
          columns = self.insert_column_keys(options)
          records.each do |record|
            #          STDERR.puts record.inspect
            begin
              self.connection.select_all <<-EOF
                insert into #{table_name} (#{columns.join(', ')})
                values(#{self.values_sql(columns, record)});
              EOF
              count += 1
            rescue Exception=>e
              if options[:ignore_exception] then
                self.logger.info Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO) Exception: #{e}")
              else
                raise e
              end
            end
          end
          self.logger.info Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO) insert #{count} records into #{table_name}")
          return count
        end
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::Insert::BaseMethods
end

