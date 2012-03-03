require 'action_controller'
require 'action_controller_extensions/read_params'

module ActionControllerExtensions
  module BaseMethods
    def self.included(base)
      base.extend ClassMethods
    end
    module ClassMethods
    end
  end
end

class ActionController::Base
  include ActionControllerExtensions::BaseMethods
end
