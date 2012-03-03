dirpath = File.expand_path(File.dirname(__FILE__))
$:.push(dirpath)

require 'rubygems'
require 'postgres'
require 'db_escape.rb'

module PgsqlUtil
  
  def self.get_schema_name(table_name)
    if table_name =~ /\./ then
      return $`
    else
      return 'public'
    end
  end
  
  def self.get_table_name(table_name)
    if table_name =~ /\./ then
      return $'
    else
      return table_name
    end
  end
  
  def self.get_table_format(conn, table_name)
    schema_name = self.get_schema_name table_name
    table_name = self.get_table_name table_name
    
    res = conn.exec <<EOF
      select column_name, data_type
      from information_schema.columns 
      where table_catalog = current_database()
        and table_schema = '#{schema_name}' 
        and table_name='#{table_name}' 
      order by ordinal_position
EOF
    ret = []
    res.each do |row|
      ret.push row
    end
    return ret
  end
  
  def self.escape_line(line)
    line.gsub(/[\0]/, '').split(/\t/, -1).map!{ |item|
      if item == '\\N' then
        item
      elsif item =~ /\\/ then
        item = DbEscape.db_escape item
      else
        item
      end
    }.join("\t")
  end


  def self.index_exist?(conn, index_name)
    if index_name =~ /^([0-9a-z_]+)\./ then
      schema_name = $1
      index_name = $'
    end
    
    res = conn.exec "select 1 from pg_indexes where schemaname = '#{schema_name}' and indexname = '#{index_name}' limit 1;"
    return res.num_tuples == 1
  end

  def self.schema_exist?(conn, schema_name)

    res = conn.exec <<EOF
      select 1 from information_schema.schemata
      where catalog_name=current_database()
        and schema_name = '#{schema_name}'
        limit 1;
EOF
    return res.num_tuples == 1
  end

  def self.table_exist?(conn, table_name)
    schema_name = self.get_schema_name table_name
    table_name = self.get_table_name table_name

    res = conn.exec <<EOF
      select 1 from information_schema.tables
      where table_catalog=current_database()
        and table_schema = '#{schema_name}'
        and table_name = '#{table_name}'
        limit 1;
EOF
    return res.num_tuples == 1
  end

  def self.table_empty?(conn, table_name)
    return false if ! self.table_exist?(conn, table_name)
    result = conn.exec "select 1 from #{table_name} limit 1;"
    return result.num_tuples == 0
  end
  
  def self.copy_from_data(pgconn, table_name, data_path, options = {})
    data_path_ftype = File.ftype(data_path)
    ret_flag = true
    if data_path_ftype == 'file' then
      STDERR.puts "copy #{table_name} from '#{data_path}'"
      ret = self.copy_from_file(pgconn, table_name, data_path, options)
      return false if ! ret
    elsif data_path_ftype == 'directory' then
      Dir.entries(data_path).sort.each do |filename|
        if filename =~ /^[0-9]{14}$/ then
          STDERR.puts "copy #{table_name} from '#{data_path}/#{filename}'"
          ret = self.copy_from_file(pgconn, table_name, "#{data_path}/#{filename}", options)
          ret_flag = false if ! ret
        end
      end
    end
    return ret_flag
  end

  def self.copy_from_file(pgconn, table_name, file_path, options = {})
#    unit_line_size = 10000
#    options[:escape] = true if options[:escape] != false
    logline = nil
#    STDERR.puts file_path
    copy_option = ''
    if options[:tsv] then
      copy_option = "CSV DELIMITER AS '\t' NULL AS E'\\\\N'"
    end


    begin
      STDERR.puts "copy #{table_name} from stdin #{copy_option};"
      pgconn.exec("copy #{table_name} from stdin #{copy_option};")
  #    puts command
      line_count = 0
      open(file_path, 'r') do |file|
        while line = file.gets do
          if 0 < line_count && line_count % 10000 == 0 then
            STDERR.puts "#{line_count} lines copied"
            pgconn.endcopy
            STDERR.puts "copy #{table_name} from stdin #{copy_option};"
            pgconn.exec("copy #{table_name} from stdin #{copy_option};")
          end
          line_count += 1
          if options[:escape] then
            line = self.escape_line line.chomp
            line += "\n"
          end
#          STDERR.puts line
#          STDERR.puts line.split(/\t/)[7]
          pgconn.putline line
#          break if line_count == 1
        end
      end
      STDERR.puts "Done. #{line_count} lines copied"
      pgconn.endcopy
    rescue Exception=> e
#      STDERR.puts logline
#      count = 0
#      logline.split(/\t/).each do |val|
#        STDERR.puts "#{count}: #{val}"
#        count+=1
#      end
      STDERR.puts e.message
#      STDERR.puts e.backtrace
      return false
    end
    return true
  end

  def self.copy_to_file(pgconn, table_name, file_path, options = {})
    unit_line_size = 100000
    options[:escape] = true if options[:escape] != false
    begin
      pgconn.exec("copy #{table_name} to stdout;")
  #    puts command
      line_count = 0
      
      File.open(file_path, 'w') do |file|
        copydone = false
      
        while !copydone
          copybuf = pgconn.getline
      
          if !copybuf
            copydone = true
          else
            if copybuf == "\\."
              copydone = true
            else
              line_count += 1
              file.puts(copybuf)
              STDERR.puts "#{line_count} lines copied" if line_count % unit_line_size == 0
            end
          end
        end
        file.flush
        pgconn.endcopy
        file.close
      end
      STDERR.puts "Done. #{line_count} lines copied"
    rescue Exception=> e
      STDERR.puts e.message.gsub(/ERROR/, 'INFO')
    end
  end
  
  def self.get_option_hash(psql_option)
    psql_option_list=psql_option.split(/\s+/)
    ret = {}
    ret[:db_host]='localhost'
    ret[:db_port]=5432
    ret[:db_name]='db'
    ret[:db_user]='postgres'
    ret[:db_password]=''

    while 0 < psql_option_list.size do
      val = psql_option_list.shift
      case val
      when '-h'
        ret[:db_host] = psql_option_list.shift
      when '-p'
        ret[:db_port] = psql_option_list.shift.to_i
      when '-U'
        ret[:db_user] = psql_option_list.shift
      when '-P'
        ret[:db_password] = psql_option_list.shift
      when '-d'
        ret[:db_name] = psql_option_list.shift
      end
    end
    return ret
  end

  def self.get_connection_from_option(psql_option)
    ret = self.get_option_hash(psql_option)
    return PGconn.open(ret[:db_host], ret[:db_port], "", "", ret[:db_name], ret[:db_user], ret[:db_password])
  end

  def self.select_into_table(pgconn, table_name, select_query, options = {})
    sql_query_list = []
    next_prefix = options[:next_prefix] || 'next'
    
    schema_name = PgsqlUtil.get_schema_name table_name
    table_name = PgsqlUtil.get_table_name table_name
    full_table_name = "#{schema_name}.#{table_name}"
    
    if ! self.schema_exist? pgconn, schema_name then
      self.exec_query pgconn, "create schema #{schema_name}"
    end
    
    tmp_table = "#{schema_name}.#{next_prefix}_#{table_name}"

    self.exec_query pgconn, "begin;"
    if self.table_exist? pgconn, tmp_table then
      self.exec_query pgconn, "drop table #{tmp_table};"
    end

    if select_query =~ /[^a-zA-Z0-9_\.]/ then
      sql_query = "select * into #{tmp_table} from (#{select_query}) as alias_create_table;"
    else
      sql_query = "select * into #{tmp_table} from #{select_query};"
    end
    self.exec_query pgconn, sql_query
    
    if self.table_exist? pgconn, full_table_name then
      self.exec_query pgconn, "drop table #{full_table_name};"
    end
    self.exec_query pgconn, "alter table #{tmp_table} rename to #{table_name};"
    self.exec_query pgconn, "commit;"
  

  end

  def self.create_table(pgconn, table_name, table_format, options = {})
    self.create_table_from_csv(pgconn, table_name, table_format, nil, options = {})
  end
  def self.create_table_from_csv(pgconn, table_name, table_format, csv_path, options = {})
    
    schema_name = self.get_schema_name(table_name)
    table_name = self.get_table_name(table_name)
    full_table_name = "#{schema_name}.#{table_name}"
    
    if table_format && table_format != '' then
      next_prefix = options[:next_prefix] || 'next'
      tmp_table = "#{schema_name}.#{next_prefix}_#{table_name}"
      sql_queries = []
      if ! self.schema_exist?(pgconn, schema_name) then
        sql_queries.push "CREATE SCHEMA #{schema_name};" 
      end
      if self.table_exist?(pgconn, tmp_table) then
        sql_queries.push "DROP TABLE #{tmp_table};"
      end
      sql_queries.push "CREATE TABLE #{tmp_table}#{table_format};"
      self.exec_queries(pgconn, sql_queries)
  #      STDERR.puts "copy from #{csv_path}"
      if csv_path && FileTest.exists?(csv_path) then
  #      STDERR.puts "copy from #{csv_path}"
        ret = self.copy_from_data(pgconn, tmp_table, csv_path, options)
        return false if ! ret
  #      sql_queries.push "COPY #{schema_name}.#{table_name} FROM '#{csv_path}';"
      else
        STDERR.puts "INFO: file does not exist: #{csv_path}"
      end

      if tmp_table != full_table_name then
        sql_queries = []
        sql_queries.push "begin;"
        if self.table_exist?(pgconn, full_table_name) then
          sql_queries.push "drop table #{full_table_name};"
        end
        sql_queries.push "alter table #{tmp_table} rename to #{table_name};"
        sql_queries.push "commit;"
        self.exec_queries(pgconn, sql_queries)
      end
    else
      self.exec_query pgconn, "truncate table #{full_table_name};"
      self.copy_from_data(pgconn, full_table_name, csv_path, options)      
      return false if ! ret
    end
    
    return true
  end

  def self.exec_query(pgconn, sql_query, output_error = true)
    begin
#      STDERR.puts sql_query
      pgconn.exec(sql_query)
    rescue Exception => e
      STDERR.puts e.message if output_error
      return false
    end
    return true
  end
  def self.exec_queries(pgconn, sql_query_list, output_error = true)
    ret = true
    sql_query_list.each do |sql_query|
      i_ret = self.exec_query(pgconn, sql_query, output_error)
      ret = i_ret if !i_ret
    end
    return ret
  end
  
  def self.migrate_table(conn, table_name)
    schema_name = self.get_schema_name table_name
    table_name = self.get_table_name table_name
    
    from_table_name = "#{schema_name}.next_#{table_name}"
    to_table_name = "#{schema_name}.#{table_name}"
    
    if ! self.table_exist? conn, from_table_name then
      STDERR.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S](ERROR) #{from_table_name} does not exist")
      conn.close
      return 1
    end
    
    sql_queries = []
    
    sql_queries.push "begin;"
    
    conn.exec("/* REPLICATION */ select util.drop_table_if_exists('#{to_table_name}');") 
#    if PgsqlUtil.table_exist? conn, to_table_name then
#      sql_queries.push "drop table #{to_table_name};"
#    end
    
    sql_queries.push "alter table #{from_table_name} rename to #{table_name};"
    
    sql_queries.push "commit;"
    
    ret = self.exec_queries conn, sql_queries
    return ret
  end

  def self.migrate_index(conn, table_name, column_name)
    schema_name = self.get_schema_name table_name
    table_name = self.get_table_name table_name
    
    from_index_name = "#{schema_name}.idx_next_#{table_name}_#{column_name}"
    to_index_name = "#{schema_name}.idx_#{table_name}_#{column_name}"
    
    if ! self.index_exist? conn, from_index_name then
      STDERR.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S](ERROR) #{from_index_name} does not exist")
      conn.close
      return 1
    end
    
    sql_queries = []
    
    sql_queries.push "begin;"
    
    if self.table_exist? conn, to_index_name then
      sql_queries.push "drop index #{to_index_name};"
    end
    
    sql_queries.push "alter index #{from_index_name} rename to idx_#{table_name}_#{column_name};"
    
    sql_queries.push "commit;"
    
    ret = self.exec_queries conn, sql_queries
    return ret
  end

end

