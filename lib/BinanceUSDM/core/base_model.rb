# frozen_string_literal: true

module BinanceUSDM
  # Base model class for all domain models.
  # Provides common initialization and attribute access.
  class BaseModel
    attr_reader :attributes
    
    # Initialize model with attributes
    # @param attributes [Hash] Model attributes
    def initialize(attributes = {})
      @attributes = (attributes || {}).dup
      assign_attributes(@attributes)
    end
    
    # Access attributes via method calls
    # @param method_name [Symbol] Attribute name
    # @return [Object] Attribute value
    def method_missing(method_name, *args, &block)
      if method_name.to_s.end_with?('?')
        value = send(method_name.to_s.chomp('?').to_sym)
        return value.respond_to?(:empty?) ? !value.empty? : !!value
      end
      
      super
    end
    
    # Check if method can be called
    # @param method_name [Symbol] Method name
    # @param include_private [Boolean] Include private methods
    # @return [Boolean]
    def respond_to_missing?(method_name, include_private = false)
      attributes.key?(method_name) || super
    end
    
    # Convert to hash
    # @return [Hash] Attributes as hash
    def to_h
      attributes.dup
    end
    alias_method :to_hash, :to_h
    
    # String representation
    # @return [String]
    def inspect
      "#<#{self.class.name} #{to_h.inspect}>"
    end
    
    # Equality check
    # @param other [Object] Object to compare
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) && other.to_h == to_h
    end
    
    private
    
    # Assign attributes to instance variables
    # @param attrs [Hash] Attributes to assign
    def assign_attributes(attrs)
      attrs.each do |key, value|
        instance_variable_set("@#{key}", value)
        
        # Create reader method if not exists
        unless self.class.method_defined?(key)
          self.class.define_method(key) { instance_variable_get("@#{key}") }
        end
      end
    end
  end
end
