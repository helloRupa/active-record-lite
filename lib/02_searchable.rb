require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_str = params.keys.join(' = ? AND ') + ' = ?'

    res = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_str}
    SQL

    res.map { |row| new(row) }
  end
end

class SQLObject
  extend Searchable
end
