module ActiveRecordExtensions
  module MethodMissing
    module BaseMethods
      def self.included(base)
        base.extend ClassMethodMissing
        base.extend ClassMethods
      end
  
      module ClassMethodMissing
        def method_missing(method_id, *args, &block)
          method_name = method_id.to_s
          if mh = self.match_create_hash_method?(method_name) \
            || mh = self.match_update_all_method?(method_name) \
            || mh = self.match_delete_dupulication_method?(method_name) then
            attribute_names = mh[:attribute_names]
            if all_attributes_exists?(attribute_names) then
              options = mh[:options]
              args.push(options) if options
              #        STDERR.puts options if options
              return self.send mh[:method_id], attribute_names, *args
            else
              return super
            end
          else
            return super
          end
        end
        def match_update_all_method?(method_id)
          method_name = method_id.to_s
          if method_name =~ /^update(_and_save)?_all_by_([a-z][a-z0-9_]*)$/ then
            save_flag = $1 != nil
            return {:method_id=>:update_all_by, :attribute_names => $2.split('_and_'), :options=>{:save=> save_flag}}
          end
          return nil      
        end
        def match_create_hash_method?(method_id)
          method_name = method_id.to_s
          if method_name =~ /^(create_hash_by)_([a-z][a-z0-9_]*)$/ then
            return {:method_id=>$1, :attribute_names=>$2.split('_and_')}
          end
          return nil      
        end
  
        def match_delete_dupulication_method?(method_id)
          method_name = method_id.to_s
          if method_name =~ /^(delete_dupulication_by)_([a-z][a-z0-9_]*)$/ then
            return {:method_id=>$1, :attribute_names=>$2.split('_and_')}
          end
          return nil      
        end
      end
      module ClassMethods
        def include_dynamic_updator
          include ClassMethodMissing
        end
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::MethodMissing::BaseMethods
end

