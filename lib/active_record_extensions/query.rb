module ActiveRecordExtensions
  module Query
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def query_hash_by(key_list, query)
          res = self.query_by_sql query
          return ArrayOfHash.split_records_by res, key_list
        end
        
        def query_by_sql(query)
          begin
            ret = self.connection.select_all(query)
            ret.each do |row|
              row.keys.each do |key|
                if key.instance_of?(String) then
                  row[key.intern] = row[key]
                  row.delete key
                end
              end
            end
            return ret
          rescue Exception=>e
  #          logger.debug e
  #          logger.debug e.backtrace
            raise e
            return []
          end
        end
        
        alias :sql_query :query_by_sql

        def test_by_sql(sql)
          table_name ||= self.table_name
          begin
            self.connection.select_all sql
            return true
          rescue Exception=>e
            self.logger.info Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)  Exception: #{e}")
            return false
          end
        end
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::Query::BaseMethods
end

