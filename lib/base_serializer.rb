# frozen_string_literal: true

require_relative "base_serializer/version"
require 'time'
require 'bigdecimal'

module BaseSerializer
  class Error < StandardError; end
  class RuntimeError < Error; end
  EMPTY_HASH = {}.freeze

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      attr_reader :object, :context
    end
  end

  class Field
    attr_reader :name, :serializer, :default_fields, :default, :predicate_name
    def initialize(name:, serializer: nil, default_fields: nil, default: true)
      @name = name
      @serializer = serializer
      @default_fields = default_fields
      @default = default
      @predicate_name = :"#{name}?"
    end
  end

  SelectedField = Struct.new(:field, :nested_serializer, :serializer_method, keyword_init: true)

  module ClassMethods
    # Define a field
    # @param name [Symbol] field name
    # @param serializer [#serialize] Serializer class to serialize the field value. serialier must have #serialize method.
    # @param fields [Array<String>] fields to serialize nested object
    # @param default [Boolean] whether the field is serialized by default
    # @example
    #   field :name
    #   field :users, serializer: UserSerializer
    def field(*field_names, serializer: nil, fields: nil, default: true)
      @fields ||= {}
      @default_field_names = nil
      field_names.each do |name|
        @fields[name] = Field.new(name: name, serializer: serializer, default_fields: fields, default: default)
      end
    end

    # Serialize an object to hash.
    # @param object [Object | Array<Object>] object to serialize. If object is an array, it returns an array of serialized objects.
    # @return [Hash | Array<Hash>]
    def serialize(object, **args)
      new(**args).serialize(object)
    end

    # Return fields defined by #field
    # @return [Hash<Symbol, Field>]
    def fields
      @fields ||= {}
    end

    def default_field_names
      @default_field_names ||= fields.values.filter_map { |field| field.name if field.default }.freeze
    end
  end

  def initialize(context: {}, fields: nil)
    @context = context
    @field_selector = FieldSelector.new(fields: fields || [:*], serializer: self.class)
    @child_fields = @field_selector.child_fields
    @selected_fields = @field_selector.field_names.filter_map do |field_name|
      field = self.class.fields[field_name]
      next unless field

      SelectedField.new(
        field: field,
        nested_serializer: build_nested_serializer(field),
        serializer_method: respond_to?(field.name)
      )
    end.freeze
  end

  def serialize(object)
    is_hash_like = object.respond_to?(:keys) || object.is_a?(Struct)
    if !is_hash_like && object.is_a?(Array)
      length = object.length
      result = Array.new(length)
      index = 0

      while index < length
        result[index] = serialize_one(object[index])
        index += 1
      end

      result
    elsif !is_hash_like && object.respond_to?(:each)
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

  private

  def serialize_one(object)
    @object = object

    hash = {}
    selected_fields = @selected_fields
    index = 0

    while index < selected_fields.length
      selected_field = selected_fields[index]
      value = field_value(selected_field)
      hash[selected_field.field.name] = cast_value(value)
      index += 1
    end

    @object = nil

    hash
  end

  def build_nested_serializer(field)
    return unless field.serializer

    field.serializer.new(
      context: context,
      fields: @child_fields[field.name] || field.default_fields
    )
  end

  def field_value(selected_field)
    field = selected_field.field

    if selected_field.nested_serializer
      value = object.public_send(field.name)
      if value
        selected_field.nested_serializer.serialize(value)
      else
        nil
      end
    else
      if selected_field.serializer_method
        send(field.name)
      elsif object.respond_to?(field.name)
        object.public_send(field.name)
      elsif object.respond_to?(field.predicate_name)
        object.public_send(field.predicate_name)
      else
        raise RuntimeError, "Field `#{field.name}` is not defined on #{object.inspect}"
      end
    end
  end

  class FieldSelector
    attr_reader :field_names, :child_fields
    def initialize(fields:, serializer:)
      @child_fields = fields[-1].is_a?(Hash) ? fields[-1] : EMPTY_HASH
      @field_names = []
      seen = {}

      fields.each do |field_name|
        next if field_name.is_a?(Hash)

        names =
          if field_name == :* || field_name == '*'
            serializer.default_field_names
          else
            [field_name]
          end

        names.each do |name|
          next if seen[name]

          seen[name] = true
          @field_names << name
        end
      end

      @child_fields.each_key do |field_name|
        next if seen[field_name]

        seen[field_name] = true
        @field_names << field_name
      end
    end
  end
end
