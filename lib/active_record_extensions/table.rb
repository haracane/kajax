module ActiveRecordExtensions
  module Table
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def get_schema_name(table_name)
          if table_name =~ /\./ then
            return $`
          else
            return 'public'
          end
        end
        
        def get_table_name(table_name)
          if table_name =~ /\./ then
            return $'
          else
            return table_name
          end
        end
  
        def test_table_exists?(table_name=nil)
          table_name ||= self.table_name
          return test_by_sql "select 1 from #{table_name} limit 1;"
        end
        
        def filter_exist_tables(table_names)
          cond_list = table_names.map { |table_name|
            schema_name = self.get_schema_name table_name
            table_name  = self.get_table_name table_name
            "(table_schema = #{self.sanitize schema_name} and table_name = #{self.sanitize table_name})"
          }
          
          res = self.query_by_sql <<-EOF
            select table_schema || '.' || table_name as table_name
            from information_schema.tables
            #{SqlUtil.where_sql(SqlUtil.or_cond(cond_list))};
          EOF
          return res.map{|row| row[:table_name]}
        end
        
        
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::Table::BaseMethods
end

