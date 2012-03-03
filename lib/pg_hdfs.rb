dirpath = File.expand_path(File.dirname(__FILE__))
$:.push(dirpath)

require 'rubygems'
require 'postgres'
require 'db_escape.rb'
require 'pgsql_util.rb'


module PgHdfs
  def self.pg_to_hdfs(pgconn, hadoop_home, pg_table, hdfs_path, options = {})
    return self.db_to_hdfs(pgconn, hadoop_home, pg_table, hdfs_path, options)
  end
  def self.db_to_hdfs(pgconn, hadoop_home, select_query, hdfs_path, options = {})
    options = {} if options == nil

    if select_query =~ /[^a-zA-Z0-9_\.]/ then
      pg_table = nil
    else
      pg_table = select_query
    end
    
    exist_flag = true

    if pg_table then
      begin
        pgconn.exec "select * from #{pg_table} limit 1;"
      rescue Exception => e
#        STDERR.puts "ERROR: #{pg_table} does not exist"
        exist_flag = false
      end
    end

    tmp_dir = '~/.tmp'
    if ! FileTest.exists?(tmp_dir) then
      system "mkdir -p #{tmp_dir}"
    end
    tmp_path = `mktemp #{tmp_dir}/#{hdfs_path.gsub(/\//, '.')}.XXXX`
    tmp_path.chomp!
    system "chmod 666 #{tmp_path}"

    
    File.open(tmp_path, 'w') do |output_file|
      line_count = 0
      if exist_flag then
        begin
          sql_query = "copy #{select_query} to stdout"
          STDERR.puts sql_query
          pgconn.exec(sql_query)
    
          while (line = pgconn.getline) != nil && line != "\\." do
            output_file.puts line
            line_count += 1
            STDERR.puts "#{line_count} lines copied" if line_count % 100000 == 0
          end
        rescue Exception=>e
          STDERR.puts e.message.gsub(/ERROR/, 'INFO')
        ensure
          output_file.close        
        end
        STDERR.puts "Done. #{line_count} lines copied"
      end
      
      file_stat = File::stat(tmp_path)
      STDERR.puts "File Size = #{file_stat.size}"

#      if 0 < line_count && 0 < file_stat.size then
      if system "#{hadoop_home}/bin/hadoop dfs -test -e #{hdfs_path}" then
        command = "#{hadoop_home}/bin/hadoop dfs -rmr #{hdfs_path}"
        STDERR.puts command
        system command
      end

      command = "#{hadoop_home}/bin/hadoop dfs -put #{tmp_path} #{hdfs_path}"
      STDERR.puts command
      system command
#      end
    end
    File.unlink(tmp_path)
  end
  def self.hdfs_to_pg(pgconn, hadoop_home, hdfs_path, pg_table, pg_table_format, options = {})
    return self.hdfs_to_db(pgconn, hadoop_home, hdfs_path, pg_table, pg_table_format, options = {})
  end
  def self.hdfs_to_db(pgconn, hadoop_home, hdfs_path, pg_table, pg_table_format, options = {})
#    options[:escape] = true if options[:escape] != false
    options = {} if options == nil
    tmp_table = options[:tmp_table] || "#{pg_table}_tmp"

    exist_flag = true
    if ! system "#{hadoop_home}/bin/hadoop dfs -test -e #{hdfs_path}" then
#      STDERR.puts "ERROR: #{hdfs_path} does not exist"
      exist_flag = false
#      return false
    end

    if pg_table_format && pg_table_format != '' then
      
#      if PgsqlUtil.table_exist? pgconn, tmp_table
#        STDERR.puts "/* REPLICATION */ select util.drop_table_if_exists('#{tmp_table}');"
        pgconn.exec("/* REPLICATION */ select util.drop_table_if_exists('#{tmp_table}');") 
#      end

      if pg_table =~ /\./ then
        schema_name = pg_table.split(/\./).shift
        if ! PgsqlUtil.schema_exist? pgconn, schema_name then
          STDERR.puts "create schema #{schema_name};"
          pgconn.exec "create schema #{schema_name};"
        end
      end
      create_sql = "create table #{tmp_table} #{pg_table_format};"
#      STDERR.puts create_sql
      pgconn.exec(create_sql)
      copy_output_table = tmp_table
    else
      pgconn.exec "truncate table #{pg_table};"
      copy_output_table = pg_table
    end
    
    if exist_flag then
      if system "#{hadoop_home}/bin/hadoop dfs -test -d #{hdfs_path}" then
        hdfs_path="#{hdfs_path}/*"
      end
      command = "#{hadoop_home}/bin/hadoop dfs -cat '#{hdfs_path}'"
  #    STDERR.puts "INFO: [input-command] #{command}"
      line_count = 0
      begin
        STDERR.puts "copy #{copy_output_table} from stdin;"
        pgconn.exec("copy #{copy_output_table} from stdin;")
        IO.popen(command, 'r') do |file|
          while line = file.gets do
            if 0 < line_count && line_count % 10000 == 0 then
              STDERR.puts "#{line_count} lines copied"
              pgconn.endcopy
  #            STDERR.puts "copy #{copy_output_table} from stdin;"
              pgconn.exec("copy #{copy_output_table} from stdin;")
            end
            line.chomp!
            if options[:escape] then
              line = PgsqlUtil.escape_line line
              pgconn.putline line + "\n"
            else
              pgconn.putline line + "\n"
            end
    #        puts line
            line_count += 1
          end
        end
        STDERR.puts "Done. #{line_count} lines copied"
        pgconn.endcopy
      rescue Exception=> e
        STDERR.puts e.message
        return false
      end
    end


    sql_query_list = []


    if options[:distinct] then
      tmp_distinct_table = options[:distinct_tmp_table] || "#{pg_table}_disttmp"
      sql_query_list.push "select distinct * into #{tmp_distinct_table} from #{copy_output_table};"
#      sql_query_list.push "drop table #{copy_output_table};" if PgsqlUtil.table_exist? pgconn, copy_output_table
      sql_query_list.push "/* REPLICATION */ select util.drop_table_if_exists('#{copy_output_table}');"
      sql_query_list.push "begin;"
#      sql_query_list.push "drop table #{pg_table};" if PgsqlUtil.table_exist? pgconn, pg_table
      sql_query_list.push "/* REPLICATION */ select util.drop_table_if_exists('#{pg_table}');"
      sql_query_list.push "alter table #{tmp_distinct_table} rename to #{pg_table.split(/\./).pop};"
      sql_query_list.push "commit;"
    elsif copy_output_table != pg_table then
      sql_query_list.push "begin;"
#      sql_query_list.push "drop table #{pg_table};" if PgsqlUtil.table_exist? pgconn, pg_table
      sql_query_list.push "/* REPLICATION */ select util.drop_table_if_exists('#{pg_table}');"
      sql_query_list.push "alter table #{copy_output_table} rename to #{pg_table.split(/\./).pop};"
      sql_query_list.push "commit;"
    end

    sql_query_list.each do |sql_query|
      begin
#        STDERR.puts sql_query
        pgconn.exec(sql_query)
      rescue Exception => e
        STDERR.puts e.message.gsub(/ERROR/, 'INFO')
      end
    end
    return true
  end
end

