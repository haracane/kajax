dirpath = File.expand_path(File.dirname(__FILE__))
$:.push(dirpath)

require 'rubygems'
require 'mysql'

module MysqlUtil
  def self.get_option_hash(psql_option)
    psql_option_list=psql_option.split(/\s+/)
    ret = {}
    ret[:db_host]='localhost'
    ret[:db_port]=3306
    ret[:db_name]='db'
    ret[:db_user]='postgres'
    ret[:db_password]=''

    while 0 < psql_option_list.size do
      val = psql_option_list.shift
      case val
      when '-h'
        ret[:db_host] = psql_option_list.shift
      when '-P'
        ret[:db_port] = psql_option_list.shift.to_i
      when '-u'
        ret[:db_user] = psql_option_list.shift
      when '-p'
        ret[:db_password] = psql_option_list.shift
      when '-D'
        ret[:db_name] = psql_option_list.shift
      else
        if val =~ /--password=/ then
          ret[:db_password] = $'
        end
      end
    end
    return ret
  end

  def self.get_connection_from_option(psql_option)
    ret = self.get_option_hash(psql_option)
    return Mysql::connect(ret[:db_host], ret[:db_user], ret[:db_password], ret[:db_name], ret[:db_port])
  end

end

