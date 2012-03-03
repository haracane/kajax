# ViewUtil
module ActionViewExtensions
  module BaseMethods
    def self.included(base)
      base.extend ClassMethods
    end

    def external_url_for(url, options={})
      options = options.clone
      
      return url + '?' + options.keys.map{|key| "#{key}=#{URI.encode(options[key].to_s)}"}.join('&')
    end
    
    module ClassMethods
      
    end
  end
end


class ActionView::Base
  include ActionViewExtensions::BaseMethods
end