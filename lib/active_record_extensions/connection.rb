module ActiveRecordExtensions
  module Connection
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def establish_connection_from_option(adapter, db_option)
          adapter_name = adapter.to_s
          db_option_list = db_option.split /\s+/
          if adapter_name == 'mysql' then
            options = {:adapter => adapter_name,
              :host => 'localhost',
              :port => 3306,
              :username => nil,
              :password => nil,
              :database => nil}
            while 0 < db_option_list.size do
              elem = db_option_list.shift
              if elem == '-h' then
                options[:host] = db_option_list.shift if 0 < db_option_list.size
              elsif elem == '-P' then
                options[:port] = db_option_list.shift.to_i if 0 < db_option_list.size
              elsif elem == '-u' then
                options[:username] = db_option_list.shift if 0 < db_option_list.size
              elsif elem =~ /--password=/ then
                options[:password] = $'
              elsif ! options[:database]
                options[:database] = elem
              end
            end
            
            self.establish_connection options
          end
        end
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::Connection::BaseMethods
end

