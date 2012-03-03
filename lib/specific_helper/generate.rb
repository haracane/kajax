
module SpecificHelper::Generate
  def self.create_specific_helper(spec, method_name_format_list, controller, *actions)
    helpers_dir = "#{RAILS_ROOT}/app/helpers"
    spec = spec.to_s
    method_name_format_list = [method_name_format_list] if ! method_name_format_list.is_a? Array
    method_name_format_list.map!{|m| m.to_s}
    controller = controller.to_s
    
    if spec == '' then
      spec_prefix = ''
    else
      spec_prefix = "#{spec}_"
    end
    module_name = "#{controller}_#{spec_prefix}helper"
    method_codes = method_name_format_list.map{|method_name| 
      method_name = method_name.gsub(/controller_action/, "#{controller}")
      <<EOF
    def #{method_name}
    end
EOF
    }.join.chomp
    
    content = <<EOF
module #{controller.to_camel_case}
  module #{module_name.to_camel_case}
#{method_codes}
  end
end
EOF
    if ! File.exists? "#{helpers_dir}/#{controller}" then
      Dir.mkdir "#{helpers_dir}/#{controller}", 0775
    end

    self.create_code("#{helpers_dir}/#{controller}/#{module_name}.rb", content)
    
    actions.each do |action|
      action = action.to_s
      
      module_name = "#{controller}_#{action}_#{spec_prefix}helper"
      method_codes = method_name_format_list.map{|method_name| 
        method_name = method_name.gsub(/controller_action/, "#{controller}_#{action}")
        <<EOF
      def #{method_name}
      end
EOF
      }.join.chomp
      
      content = <<EOF
module #{controller.to_camel_case}
  module #{action.to_camel_case}
    module #{module_name.to_camel_case}
#{method_codes}
    end
  end
end
EOF
      if ! File.exists? "#{helpers_dir}/#{controller}/#{action}" then
        Dir.mkdir "#{helpers_dir}/#{controller}/#{action}", 0775
      end
      self.create_code("#{helpers_dir}/#{controller}/#{action}/#{module_name}.rb", content)
    end
  end
  
  def self.create_code(filepath, content)
    if File.exists? filepath then
      STDERR.puts "#{filepath} already exists"
    else
      File.open filepath, 'w', 0664 do |file|
        file.puts content
      end
      STDERR.puts "created #{filepath}"
    end
  end
  
end
