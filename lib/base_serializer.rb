# frozen_string_literal: true

require_relative "base_serializer/version"
require 'time'
require 'bigdecimal'

module BaseSerializer
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

    def relation(name, serializer:, fields: nil, default: false)
      field(name, serializer: serializer, fields: fields, default: default)
    end

    def all_fields
      fields.values.select(&:default).map(&:name)
    end

    def serialize(object, **args)
      new(**args).serialize(object)
    end

    def fields
      @fields ||= {}
    end

    def expand_field_set(field_names)
      field_names.reduce([]) do |expanded, name|
        fields_for_name =
          if name.to_s.start_with?('_')
            field_set_name = name[1..-1].to_sym
            field_sets[field_set_name]
          elsif name.to_s == '*'
            all_fields
          else
            [name]
          end

        raise "json serialize error: field set `#{name}` was not found" unless fields_for_name

        expanded + fields_for_name
      end
    end
  end

  def initialize(context: {}, fields: nil)
    @context = context

    fields ||= [:*]
    @selected_relation_fields = fields[-1].is_a?(Hash) ? fields[-1] : {}
    @selected_fields = self.class.expand_field_set(fields + @selected_relation_fields.keys)
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

  private

  def serialize_one(object)
    @object = object

    hash = {}
    selected_fields.each do |field_name, field|
      if field.serializer
        value = object.public_send(field.name)

        hash[field_name] =
          if value
            field.serializer.serialize(
              value,
              context: context,
              fields: selected_fields_for_relation(field.name) || field.default_fields
            )
          else
            nil
          end
      else
        value =
          if respond_to?(field_name)
            send(field_name)
          elsif object.respond_to?(field_name)
            object.public_send(field_name)
          elsif object.respond_to?(:"#{field_name}?")
            object.public_send(:"#{field_name}?")
          end

        hash[field_name] = cast_value(value)
      end
    end

    @object = nil

    hash
  end

  def selected_fields
    self.class.fields.slice(*@selected_fields)
  end

  def selected_fields_for_relation(relation_name)
    @selected_relation_fields[relation_name]
  end
end
