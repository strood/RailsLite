require_relative "db_connection"
require "active_support/inflector"


class SQLObject
  # Mixin Associatable module to group in all
  extend Associatable

  def self.columns
    # return an array of symbols, corrospnding to the columns in our db table
    return @columns if @columns

    cols = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      "#{self.table_name}"
    SQL

    @columns = cols[0].map(&:to_sym)
  end

  def self.finalize!
    # Adds getter and setter methods for each column
    # Called at end of the subclass definition to add the getters/setters
    # Use columns to list all comumn names, then like attr_accessor, we do getter and setters for each

    self.columns.each do |name|
      define_method(name) do
        self.attributes[name]
      end
      define_method("#{name}=") do |value|
        self.attributes[name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end

  def self.all
    # fetch all recods from database.Parse them with pase_all to get in correct format
    # return @records if @records

    db_return = DBConnection.execute(<<-SQL)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL

    parse_all(db_return)
  end

  def self.parse_all(results)
    # take raw array of hash objects, and convert them into the class type thatis currently being
    # called on
    results.map { |el| self.new(el) }
  end

  def self.find(id)
    # instead of using self.all and Array.find on the return, do a new SQP request that only
    # pulls the specific col we are looking for based on id
    db_return = DBConnection.execute(<<-SQL, id)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE
      #{table_name}.id = ?
    SQL

    parse_all(db_return).first
  end

  def initialize(params = {})
    # Iterate through each of the k,v pairs, convery k to sym and see if in columns, if not error
    # set the attribute if no error, using send.
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        self.send("#{attr_name}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    # Return a hash of all our models columns, and values
    # lazily initialize it as an empty hash in case it doesnt exist.
    @attributes ||= {}
  end

  def attribute_values
    # called in insert DB execute, returns the valus of each attribute of our class instance
    #This will be passd back in qith splat opertor to go to our SQL query
    self.class.columns.map { |col| self.send("#{col}") }
  end

  def insert
    # Insewrt a value into db
    col_names = self.class.columns.join(", ")
    question_marks = ["?"] * self.class.columns.length
    question_marks = question_marks.join(", ")

    DBConnection.execute(<<-SQL, *self.attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    # update a records attributes, similar to insert ^

    set_line = self.class.columns.map { |col| "#{col} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, *self.attribute_values, self.id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      id = ?
    SQL
  end

  def where(params)
    # search for our specific cat baes in params passed in as hash
    where_line = params.each_key.map { |key| "#{key} = ?" }.join(" AND ")

    db_return = DBConnection.execute(<<-SQL, *params.values)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{where_line}
    SQL

    parse_all(db_return)
  end

  def save
    # calls insert if record does not exist, update if already existing.
    if self.id
      self.update
    else
      self.insert
    end
  end
end


# MODULE TO EXTEND SQL OBJECT AND ADD ASSOCIATABLILITY

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    # return class name of the model called on
    @class_name.constantize
  end

  def table_name
    # returns table name of the model called on
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    # provide default values for the 3 attributes for a new SQLObject
    # :foreign_key, :primary_key, :class_name
    defaults = {
      :foreign_key => "#{name}_id".to_sym,
      :primary_key => :id,
      :class_name => name.to_s.camelcase,
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      :foreign_key => "#{self_class_name.underscore}_id".to_sym,
      :class_name => name.to_s.singularize.camelcase,
      :primary_key => :id,
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})

    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.foreign_key)
      options.model_class.where(options.primary_key => key_val).first
    end
  end

  def has_many(name, options = {})

    self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => key_val)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
    @assoc_options
  end

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options =
        through_options.model_class.assoc_options[source_name]

      through_table = through_options.table_name
      through_pk = through_options.primary_key
      through_fk = through_options.foreign_key

      source_table = source_options.table_name
      source_pk = source_options.primary_key
      source_fk = source_options.foreign_key

      key_val = self.send(through_fk)
      results = DBConnection.execute(<<-SQL, key_val)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{source_fk} = #{source_table}.#{source_pk}
        WHERE
          #{through_table}.#{through_pk} = ?
      SQL

      source_options.model_class.parse_all(results).first
    end
  end
end
