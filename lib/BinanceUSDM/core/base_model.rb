# frozen_string_literal: true

module BinanceUSDM
  # Base model class providing dynamic attribute access with camelCase to snake_case normalization
  class BaseModel
    attr_reader :attributes
    
    def initialize(attributes = {})
      @attributes = (attributes || {}).dup
      assign_attributes(@attributes)
    end
    
    def method_missing(method_name, *args, &block)
      if method_name.to_s.end_with?("?")
        attr_name = method_name.to_s.chomp("?")
        value = send(attr_name.to_sym) if respond_to?(attr_name.to_sym)
        return value.respond_to?(:empty?) ? !value.empty? : !!value
      end
      
      super
    end
    
    def respond_to_missing?(method_name, include_private = false)
      name_str = method_name.to_s
      attributes.key?(name_str) || 
        attributes.key?(name_str.to_sym) || 
        attributes.key?(to_snake_case(name_str)) || 
        super
    end
    
    def to_h
      attributes.dup
    end
    alias_method :to_hash, :to_h
    
    def inspect
      "#<#{self.class.name} #{to_h.inspect}>"
    end
    
    def ==(other)
      other.is_a?(self.class) && other.to_h == to_h
    end
    
    private
    
    def assign_attributes(attrs)
      attrs.each do |key, value|
        snake_key = to_snake_case(key)
        
        instance_variable_set("@#{key}", value)
        instance_variable_set("@#{snake_key}", value) if snake_key != key.to_s
        
        define_reader(key)
        define_reader(snake_key) if snake_key != key.to_s
      end
    end
    
    def define_reader(name)
      sym = name.to_sym
      return if self.class.method_defined?(sym)
      
      self.class.define_method(sym) { instance_variable_get("@#{name}") }
    end
    
    def to_snake_case(str)
      str.to_s
         .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
         .gsub(/([a-z\d])([A-Z])/, '\1_\2')
         .tr("-", "_")
         .downcase
    end
  end
end
