require 'rubygems'
require 'cassandra'
include Cassandra::Constants

module CassandraUtil
  def self.create_cassandra_conf_from_yaml(conf_path, key)
    if ! File.exist?(conf_path) then
      STDERR.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S]") + "(ERROR) #{conf_path} does not exist"
      return nil
    end
    
    conf = YAML.load_file(conf_path)
    
    if ! conf then
      STDERR.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S]") + "(ERROR) #{conf_path} is invalid YAML file"
      return nil
    end
    
    return conf[key]
  end

  def self.create_cassandra_client_from_hash(cassandra_conf)
    if ! cassandra_conf then
      STDERR.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S]") + "(ERROR) 'cassandra' is not configured"
      return nil
    end

    ['host', 'port', 'keyspace', 'column_family'].each do |key|
      if ! cassandra_conf[key] then
        STDERR.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S]") + "(ERROR) cassandra #{key} is not configured in #{conf_path}"
        return nil
      end
    end
    
    client = Cassandra.new(cassandra_conf['keyspace'], "#{cassandra_conf['host']}:#{cassandra_conf['port']}")
    return client
  end
  def self.create_cassandra_client_from_yaml(conf_path)

    cassandra_conf = self.create_cassandra_conf_from_yaml(conf_path, 'cassandra')
    return self.create_cassandra_client_from_hash(cassandra_conf)
  end
  
end
