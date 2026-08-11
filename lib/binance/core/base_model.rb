# frozen_string_literal: true

require 'bigdecimal'

module Binance
  module Core
    # Base model class for all domain models with BigDecimal support
    class BaseModel
      attr_reader :attributes

      def initialize(attributes = {})
        @attributes = (attributes || {}).dup
        assign_attributes(@attributes)
      end

      def method_missing(method_name, *args, &block)
        if method_name.to_s.end_with?('?')
          value = send(method_name.to_s.chomp('?').to_sym)
          return value.respond_to?(:empty?) ? !value.empty? : !value.nil?
        end

        super
      end

      def respond_to_missing?(method_name, include_private = false)
        attributes.key?(method_name) || super
      end

      def to_h
        attributes.dup
      end
      alias to_hash to_h

      def inspect
        "#<#{self.class.name} #{to_h.inspect}>"
      end

      def ==(other)
        other.is_a?(self.class) && other.to_h == to_h
      end

      private

      def assign_attributes(attrs)
        attrs.each do |key, value|
          # Convert numeric strings to BigDecimal for precision
          converted_value = convert_numeric(value)
          instance_variable_set("@#{key}", converted_value)

          self.class.define_method(key) { instance_variable_get("@#{key}") } unless self.class.method_defined?(key)
        end
      end

      def convert_numeric(value)
        case value
        when String then convert_string(value)
        when Float, Integer then BigDecimal(value.to_s)
        else value
        end
      end

      def convert_string(value)
        value.match?(/\A-?\d+\.?\d*\z/) ? BigDecimal(value) : value
      end
    end
  end
end
