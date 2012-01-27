require "shippinglogic/service"
require "shippinglogic/fedex"
require "shippinglogic/ups"

unless Object.method_defined?(:blank?)
  class Object
    def blank?
      respond_to?(:empty?) ? empty? : !self
    end
  end
end
