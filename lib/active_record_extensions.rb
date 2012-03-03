require 'active_record'
require 'active_record_extensions/bulk_insert'
require 'active_record_extensions/insert'

module ActiveRecordExtensions
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

    module ClassMethods
      
      def query_hash_by(key_list, query)
        res = self.squery_by_sql query
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
      
      def select_from(table_name, options={})
        return self.query_by_sql SqlUtil.select_sql(table_name, options)
      end
      
      alias :query_select :select_from

      def count_from(table_name, options={})
        res = self.query_by_sql SqlUtil.count_sql(table_name, options)
        return nil if ! res || res.size == 0
        return res[0][:count].to_i
      end

      alias :query_count :count_from
      
      def sql_value(val)
        return SqlUtil.sql_value(val, {:model=>self})
      end
      
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
      
      def update_value_by_keys(key_names, key_list, val_name, val_list, options={})
        table_name = options[:table_name] || self.table_name
        update_sql_list = []
        
        val_list = [val_list] if ! val_list.is_a? Array
        
        val_list.size.times do |i|
          cond_list = []
          cond_list.push options[:conditions] if options[:conditions]
          key_names.size.times do |j|
            key_name = key_names[j]
            cond_list.push "#{key_name} = #{key_list[j][i]}"
          end
          
          update_sql_list.push <<EOF
          update travel_user.user_saved_profiles
          set #{val_name} = #{self.sql_value val_list[i]}
          #{SqlUtil.where_sql cond_list};
EOF
        end
        return 0 if update_sql_list == []
        self.query_by_sql update_sql_list.join
        return update_sql_list.size
      end

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
      
      def count_with(options={})
        table_name = options[:table_name] || self.table_name
        return self.count_from(table_name, options)
      end
      
      def select_with(options={})
        table_name = options[:table_name] || self.table_name
        return self.select_from(table_name, options)
      end
      
      
      def exist_values(key, value_list, options={})
        key = key.to_s.intern if key.is_a? Symbol
        value_cond = value_list.map{|val| "#{key} = #{self.sanitize val}"}.join(' or ')
        condition_list = []
        condition_list.push SqlUtil.and_cond(options[:conditions]) if options[:conditions]
        condition_list.push value_cond
        return self.select_from(options[:table_name] || self.table_name, :conditions=>condition_list, :select=>key).map{|row| row[key]}
      end
      
      def delete_exist_values(key, value_list, options={})
        exist_value_list = self.exist_values(key, value_list, options)
        
        input_size = value_list.size
        value_list.delete_if { |val|
          exist_value_list.include? val
        }
        
        logger.info Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO) insert #{value_list.size} of #{input_size} statuses (#{exist_value_list.size} status already exists)")
      end
      
      def delete_exist_records(key, records, options={})
        value_list = records.map{|record| record[key]}
        exist_value_list = self.exist_values(key, value_list, options)
        
        records.delete_if { |record|
          exist_value_list.include? record[key]
        }
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
        
        res = self.query_by_sql <<EOF
          select table_schema || '.' || table_name as table_name
          from information_schema.tables
          #{SqlUtil.where_sql(SqlUtil.or_cond(cond_list))};
EOF
        return res.map{|row| row[:table_name]}
      end
      
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

class ActiveRecord::Base
  include ActiveRecordExtensions::BaseMethods
end

