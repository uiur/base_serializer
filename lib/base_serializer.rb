# frozen_string_literal: true

require_relative "base_serializer/version"
require 'time'
require 'bigdecimal'

module BaseSerializer
  class Error < StandardError; end
  class RuntimeError < Error; end

  class Field
    attr_reader :name, :serializer, :default_fields, :default
    def initialize(name:, serializer: nil, default_fields: nil, default: true)
      @name = name
      @serializer = serializer
      @default_fields = default_fields
      @default = default
    end
  end

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      attr_reader :object, :context
    end
  end

  module ClassMethods
    def field(*field_names, serializer: nil, fields: nil, default: true)
      @fields ||= {}
      field_names.each do |name|
        @fields[name] = Field.new(name: name, serializer: serializer, default_fields: fields, default: default)
      end
    end

    def serialize(object, **args)
      new(**args).serialize(object)
    end

    def fields
      @fields ||= {}
    end
  end

  def initialize(context: {}, fields: nil)
    @context = context
    @fields = fields
  end

  def serialize(object)
    is_hash_like = object.respond_to?(:keys) || object.is_a?(Struct)
    if !is_hash_like && object.respond_to?(:each)
      object.map do |item|
        serialize_one(item)
      end
    else
      serialize_one(object)
    end
  end

  def cast_value(value)
    case value
    when Time
      value.iso8601(3)
    when BigDecimal
      value.to_f
    else
      value
    end
  end

  def map_field_names(field_names)
    field_names.reduce([]) do |expanded, name|
      fields_for_name =
        if name.to_s == '*'
          self.class.fields.values.select(&:default).map(&:name)
        else
          [name]
        end

      expanded + fields_for_name
    end
  end

  private

  def serialize_one(object)
    @object = object

    hash = {}
    selected_fields.each do |field_name, field|
      value = field_value(field)
      hash[field_name] = cast_value(value)
    end

    @object = nil

    hash
  end

  def field_value(field)
    if field.serializer
      value = object.public_send(field.name)
      if value
        field.serializer.serialize(
          value,
          context: context,
          fields: field_selector.child_fields[field.name] || field.default_fields
        )
      else
        nil
      end
    else
      if respond_to?(field.name)
        send(field.name)
      elsif object.respond_to?(field.name)
        object.public_send(field.name)
      elsif object.respond_to?(:"#{field.name}?")
        object.public_send(:"#{field.name}?")
      else
        raise RuntimeError, "Field `#{field.name}` is not defined on #{object.inspect}"
      end
    end
  end

  def selected_fields
    self.class.fields.slice(*field_selector.field_names)
  end

  class FieldSelector
    attr_reader :fields, :serializer
    def initialize(fields:, serializer:)
      @fields = fields
      @serializer = serializer
    end

    def field_names
      serializer.map_field_names(fields + child_fields.keys)
    end

    def child_fields
      fields[-1].is_a?(Hash) ? fields[-1] : {}
    end
  end

  def field_selector
    @field_selector ||= FieldSelector.new(fields: @fields || [:*], serializer: self)
  end
end
