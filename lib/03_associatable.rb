require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.underscore + 's'
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || "#{name.to_s.downcase}_id".to_sym
    @class_name = options[:class_name] || name.to_s.camelcase
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || "#{self_class_name.to_s.downcase}_id".to_sym
    @class_name = options[:class_name] || name[0...-1].to_s.camelcase
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    b_options = BelongsToOptions.new(name, options)
    self.assoc_options[name] = b_options
    
    define_method(name) do
      val = self.send(b_options.foreign_key)
      b_options.model_class.where(b_options.primary_key => val).first
    end
  end

  def has_many(name, options = {})
    b_options = HasManyOptions.new(name, self.name, options)
    define_method(name) do
      val = self.send(b_options.primary_key)
      b_options.model_class.where(b_options.foreign_key => val)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
