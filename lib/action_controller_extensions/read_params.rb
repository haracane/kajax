module ActionControllerExtension
  module ReadParams
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
      STATUS_CODE_OK = 200
      STATUS_CODE_NO_INPUT = 410
      STATUS_CODE_INVALID_INPUT = 420
      STATUS_CODE_INTERNAL_ERROR = 440
      STATUS_CODE_OTHER_ERROR = 499
      
      def read_int_param(key, options = {})
        sc = STATUS_CODE_OK
        varname = options[:varname] || key
        
        val = params[key].to_i if params[key] && params[key] != ''
        val ||= options[:default]
        return sc if (sc = validate_from_options(val, options)) != STATUS_CODE_OK
        
        self.instance_variable_set("@#{varname}", val) if val
        return sc
      end
      
      def read_date_param(key, options = {})
        sc = STATUS_CODE_OK
        varname = options[:varname] || key
        
        val = params[key] if params[key] && params[key] != ''
        val = Date.parse val if val
        val ||= options[:default]
        return sc if (sc = validate_from_options(val, options)) != STATUS_CODE_OK
        return sc if !val
        
        self.instance_variable_set("@#{varname}", val) if val
        return sc
      end
      
      def read_int_list_param(key, options = {})
        sc = STATUS_CODE_OK
        
        varname = options[:varname] || key
        
  #        text_options = options.merge :regex=>'^-?[0-9]+$', :min=>nil, :max=>nil
        text_options = options.merge :regex=>nil, :min=>nil, :max=>nil
        return sc if (sc = read_text_list_param(key, text_options)) != STATUS_CODE_OK
        val_list = self.instance_variable_get("@#{varname}_list")
        return sc if ! val_list
        val_list.size.times { |i|
          val = val_list[i]
  #          STDERR.puts "val=#{val}"
          return STATUS_CODE_INVALID_INPUT if val !~ /^-?[0-9]+$/
          val = val.to_i
          return sc if (sc = validate_from_options(val, options)) != STATUS_CODE_OK
          val_list[i] = val
        }
        self.instance_variable_set("@#{varname}_list", val_list)
        return sc 
      end
      
      def read_text_param(key, options = {})
        sc = STATUS_CODE_OK
        
        regex = options[:regex]
        varname = options[:varname] || key
        
        val = params[key] if params[key] && params[key] != ''
        
        val ||= options[:default]
        return sc if (sc = validate_from_options(val, options)) != STATUS_CODE_OK
        return sc if !val
        
        if regex then
          return STATUS_CODE_INVALID_INPUT if val !~ /#{regex}/
        end
        
        self.instance_variable_set("@#{varname}", val) if val
        return sc
      end
      
      def read_text_list_param(key, options = {})
        sc = STATUS_CODE_OK
        
        regex = options[:regex]
        varname = options[:varname] || key
  
        sc = read_text_param(key, options.merge(:default=>nil))
        return sc if sc != STATUS_CODE_OK
        
        val = self.instance_variable_get("@#{varname}")
        
  #        STDERR.puts "@#{varname}=#{val}"
  
        if !val then
          self.instance_variable_set("@#{varname}_list", options[:default]) if options[:default]
          return sc 
        end
        
        val.gsub!(/　/, ' ')
        if val =~ /^\s*$/ then
          self.instance_variable_set("@#{varname}_list", options[:default]) if options[:default]
          return sc
        end
        
        val_list = val.split(/\s+/)
        
        if regex then
          val_list.each do |keyword|
            return STATUS_CODE_INVALID_INPUT if keyword !~ /#{regex}/
          end
        end
        
        self.instance_variable_set("@#{varname}", val)
        self.instance_variable_set("@#{varname}_list", val_list)
        return sc
      end
      
      def validate_from_options(val, options)
       (sc = validate_constraint(val, options[:constraints])) != STATUS_CODE_OK \
        || (sc = validate_min_max(val, options[:min], options[:max])) != STATUS_CODE_OK
        return sc
      end
      
      def validate_min_max(val, min_val, max_val)
        return STATUS_CODE_OK if val == nil
        return STATUS_CODE_INVALID_INPUT if min_val && val < min_val
        return STATUS_CODE_INVALID_INPUT if max_val && max_val < val
        return STATUS_CODE_OK
      end
      
      def validate_http(str)
  #        STDERR.puts "validate_http: #{str}"
        begin
          uri_list = URI.split(str)
  #          STDERR.puts "#{uri_list.inspect}"
          protocol = uri_list.first 
          return protocol == 'http'
        rescue
          return false
        end
      end
      
      def validate_constraint(val, constraint)
        return STATUS_CODE_OK if constraint == nil
        if constraint.is_a?(Array) then
          constraint.each do |c|
            sc = validate_constraint(val, c)
            return sc if sc != STATUS_CODE_OK
          end
        elsif constraint == :not_nil then
          return STATUS_CODE_NO_INPUT if val == nil
        elsif val == nil then
          return STATUS_CODE_OK
        elsif constraint == :http then
          return STATUS_CODE_NO_INPUT if !validate_http(val)
        end
        return STATUS_CODE_OK
      end
    end
    module ClassMethods
    end
  end
end

class ActionController::Base
  include ActionControllerExtension::ReadParams::BaseMethods
end
