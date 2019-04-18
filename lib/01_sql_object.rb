require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    res = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @columns = res[0].map(&:to_sym)
  end

  def self.finalize!
    columns.each do |col|
      define_method(col) { attributes[col] }
      define_method("#{col}=") { |val| attributes[col] = val }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= name.tableize
  end

  def self.all
    res = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(res)
  end

  def self.parse_all(results)
    results.map { |row| new(row) }
  end

  def self.find(id)
    res = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    return nil if res.empty?
    new(res[0])
  end

  def initialize(params = {})
    params.each do |k, v|
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(k.to_sym)
      self.send("#{k}=", v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.each_with_object([]) do |col, arr|
      arr << self.send(col)
    end
  end

  def insert
    col_names = self.class.columns[1..-1].map(&:to_s).join(', ')
    q_marks = (['?'] * (self.class.columns.length - 1)).join(', ')

    DBConnection.execute(<<-SQL, *attribute_values[1..-1])
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{q_marks})
    SQL

    self.id = DBConnection.instance.last_insert_row_id
  end

  def update
    set_str = attributes.to_a[1..-1].reduce('') do |str, pair|
      str += "#{pair[0]} = ?, "
    end[0..-3]

    DBConnection.execute(<<-SQL, *attribute_values[1..-1], self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_str}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
