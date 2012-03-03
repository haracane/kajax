# SpecificHelper
module SpecificHelper
  module ControllerActionMethodCaller
    def call_controller_action_method(spec)
      self.send(spec.to_s.gsub(/controller_action/, "#{params[:controller]}_#{params[:action]}"))
    end
    alias :call_specific_helper_method :call_controller_action_method
  end
  
  module ActionControllerExtensions
    module BaseMethods
      def self.included(base)
        base.extend ClassMethods
      end
      include SpecificHelper::ControllerActionMethodCaller
      module ClassMethods
        def include_specific_helper(options)
          specs = options[:spec]
          actions = options[:action]
          if specs && actions then
            specs = [specs] if ! specs.is_a? Array
            actions = [actions] if ! actions.is_a? Array
            
            specs.each do |spec|
              actions.each do |action|
                controller = self.name.gsub(/Controller/, '').downcase
                action = action.to_s
                self.instance_eval do
                  include eval("#{controller}/#{action}/#{controller}_#{action}_#{spec}_helper".classify)
                end
              end
            end
          end
        end
      end
    end
  end
  module ActionViewExtensions
    module BaseMethods
      include SpecificHelper::ControllerActionMethodCaller
    end
  end
end

def to_camel_case
  return self.classify
end


class ActionController::Base
  include SpecificHelper::ActionControllerExtensions::BaseMethods
end

class ActionView::Base
  include SpecificHelper::ActionViewExtensions::BaseMethods
end
