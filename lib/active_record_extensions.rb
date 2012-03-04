require 'active_record'
require 'active_record_extensions/bulk_insert'
require 'active_record_extensions/compare'
require 'active_record_extensions/connection'
require 'active_record_extensions/conversions'
require 'active_record_extensions/count'
require 'active_record_extensions/delete'
require 'active_record_extensions/insert'
require 'active_record_extensions/method_missing'
require 'active_record_extensions/query'
require 'active_record_extensions/select'
require 'active_record_extensions/update'

module ActiveRecordExtensions
  module BaseMethods
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def force_find(*args)
        uncached { find(*args) }
      end
    end
  end
end

class ActiveRecord::Base
  include ActiveRecordExtensions::BaseMethods
end

