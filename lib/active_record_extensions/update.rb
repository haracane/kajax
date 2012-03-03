module ActiveRecordExtensions
  module Update
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def update_all_by(attribute_names, record_list, update_record_list, options = {})
          attribute_ids = attribute_names.map{|attribute_name| attribute_name.to_sym}
          record_hash = self.create_hash_by(attribute_ids, record_list)
          #        STDERR.puts record_hash
          #        STDERR.puts record_hash.keys
          
          update_record_list.each do |update_record|
            next if update_record.nil?
            key_list = attribute_ids.map{|key| update_record[key]}
            #          STDERR.puts key_list.class
            record = record_hash.fetch_with_keys key_list
            #          STDERR.puts record_hash[key_list[0]]
            #          STDERR.puts update_record
            update_flag = false
            record = self.new if record == nil
            
            #                STDERR.puts update_record.inspect
            record_columns_hash = self.columns_hash
            update_record.attribute_names.each do |key|
              new_val = update_record[key]
              #                   STDERR.puts "check: #{key}, #{new_val}"
              if new_val != nil && record[key] != new_val then
                #STDERR.puts "update value: #{key}: #{record[key]} #{record[key].class}->#{new_val} #{new_val.class}"
                record[key] = new_val
                update_flag = true
              end
            end
            #          puts options[:save]
            #          STDERR.puts record
            if update_flag then
              if options[:save] then
                record.save
                #STDERR.puts "saved #{record.inspect}"
              else
                #STDERR.puts "updated #{record.inspect}"
              end
            end
          end
          
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
            
            update_sql_list.push <<-EOF
              update travel_user.user_saved_profiles
              set #{val_name} = #{self.sql_value val_list[i]}
              #{SqlUtil.where_sql cond_list};
            EOF
          end
          return 0 if update_sql_list == []
          self.query_by_sql update_sql_list.join
          return update_sql_list.size
        end
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::Update::BaseMethods
end

