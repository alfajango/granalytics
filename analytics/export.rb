module Analytics::Export
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      attr_accessor :data
    end
  end

  def initialize(loaded_data)
    self.data = loaded_data
  end

  def records
    data[self.class.rows]
  end

  # {
  #   :username => ["blah", "blah2", "blah3"],
  #   :role => ["admin", "owner", "owner"], ...
  # }
  def schema_records
    Hash.new { |hash, key| hash[key] = [] }.tap do |h|
      self.class.schema.each do |column, value|
        h[column] = self.records.each_with_index.map do |record, i|
          if record.respond_to? value
            record.send(value)
          else
            self.send(value, record, i)
          end
        end
      end
    end
  end

  def generate_csv(path, file_name=nil)
    unless File.exists?(path) && File.directory?(path)
      Dir.mkdir(path)
    end
    file_name ||= "#{self.class.name.underscore}.csv"

    CSV.open(File.join(path, file_name), "wb") do |csv|
      # Write header row
      csv << self.class.schema.keys

      # Zip schema_records values from each key
      self.schema_records.values.transpose.each{ |record| csv << record }
    end
  end

  module ClassMethods
    def set_schema(schema_hash)
      @schema = schema_hash
    end

    def schema
      @schema
    end

    def rows_by(collection)
      @rows = collection
    end

    def rows
      @rows
    end
  end
end
