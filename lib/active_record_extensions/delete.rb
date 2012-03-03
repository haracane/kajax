module ActiveRecordExtensions
  module Delete
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def delete_dupulication_by(attribute_names, record_list)
          #        STDERR.puts "delete_dupulication"
          attribute_ids = attribute_names.map{|attribute_name| attribute_name.to_sym}
          hash = {}
          record_list.each do |record|
            key_list = record.values_at(*attribute_ids)
            #          STDERR.puts key_list
            old_record = hash.fetch_with_keys(key_list)
            if old_record then
              STDERR.puts "delete [#{old_record}]"
              old_record.delete
            end
            hash.store_with_keys(key_list, record)
          end
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
        
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::Delete::BaseMethods
end

