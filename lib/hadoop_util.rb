module HadoopUtil

  def self.pig_join(table_prefix, left_table_path, left_table_format, right_table_path, right_table_format, left_key, right_key, left_output_columns, right_output_columns, output_path)
    output_columns = left_output_columns.clone.map!{|column| "left_table::#{column}"}.concat(right_output_columns.clone.map!{|column| "right_table::#{column}"})
    output_columns_str = output_columns.join(', ')
    pig_script = <<EOF
#{table_prefix}_pig_join_left  = LOAD '#{left_table_path}' USING PigStorage('\\t') AS #{left_table_format};
#{table_prefix}_pig_join_right = LOAD '#{right_table_path}' USING PigStorage('\\t') AS #{right_table_format};
#{table_prefix}_pig_join_join  = JOIN #{table_prefix}_pig_join_left BY #{left_key}, #{table_prefix}_pig_join_right BY #{right_key};
#{table_prefix}_pig_join_select = FOREACH #{table_prefix}_pig_join_join GENERATE #{output_columns_str};
group_table = GROUP filter_table by (#{output_columns_str});
result =  FOREACH group_table GENERATE flatten($0), COUNT(select_table);
STORE result INTO '#{output_path}' USING PigStorage();
EOF

    return pig_script
  end
  def self.pig_load(output_table, table_path, table_format)
    return <<EOF
#{output_table}  = LOAD '#{left_table_path}' USING PigStorage('\\t') AS #{table_format};
EOF
  end
  def self.pig_join(left_table, right_table, output_table, left_key, right_key, left_output_columns, right_output_columns, output_path)
    table_prefix = output_table
    output_columns = left_output_columns.map{|column| "#{left_table}::#{column}"}.concat(right_output_columns.clone.map!{|column| "#{right_table}::#{column}"})
    output_columns_str = output_columns.join(', ')
    pig_script = <<EOF
#{output_table}  = JOIN #{table_prefix}_pig_join_left BY #{left_key}, #{table_prefix}_pig_join_right BY #{right_key};
#{output_table} = FOREACH #{table_prefix}_pig_join_join GENERATE #{output_columns_str};
group_table = GROUP filter_table by (#{output_columns_str});
result =  FOREACH group_table GENERATE flatten($0), COUNT(select_table);
STORE result INTO '#{output_path}' USING PigStorage();
EOF

    return pig_script
  end
=begin
    pig_script_path = options[:pig_script_path] || "/tmp/#{output_path.gsub(/\//, '_')}.pig"
    dir_path = File.dirname(pig_script_path)
    if ! FileTest.exists?(dir_path) then
      system "mkdir -p #{dir_path}"
    end
=end
#    open(pig_script_path, 'w') do |file|
#      file.puts pig_script
#      file.flush
#      file.close
#    end
#    system 'JAVA_HOME=/usr/java/default/ /usr/bin/pig -f #{pig_script_path}'
#    return pig_script_path
#  end

end