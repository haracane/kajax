
module SymbolExtensions
  module Symbol
    module Conversions
      def to_proc
        Proc.new{|x| x.send(self)}
      end
    end
  end  
end

class Symbol
  include SymbolExtensions::Symbol::Conversions
end
