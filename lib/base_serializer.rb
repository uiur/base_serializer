# frozen_string_literal: true

require_relative "base_serializer/version"
require 'time'
require 'bigdecimal'

module BaseSerializer
  Field = Struct.new(:name, keyword_init: true)
  Relation = Struct.new(:name, :serializer_class, :default_fields, keyword_init: true)

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      attr_reader :object, :context
    end
  end

  module ClassMethods
    def field(*field_names)
      @fields ||= {}
      field_names.each do |name|
        @fields[name] = Field.new(name: name)
      end
    end

    def all_fields
      fields.keys
    end

    def relation(name, serializer:, fields: nil, default: false)
      @relations ||= {}
      @relations[name] = Relation.new(name: name, serializer_class: serializer, default_fields: fields)
    end

    def serialize(object, **args)
      new(**args).serialize(object)
    end

    def relations
      @relations ||= {}
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

    fields ||= self.class.fields.keys
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
    selected_fields.each do |field_name, _|
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

    selected_relations.each do |_, relation|
      relation_object = object.public_send(relation.name)
      args = {
        context: context,
        fields: selected_fields_for_relation(relation.name) || relation.default_fields
      }

      hash[relation.name] = relation_object && relation.serializer_class.new(**args).serialize(relation_object)
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

  def selected_relations
    self.class.relations.slice(*@selected_fields)
  end
end
