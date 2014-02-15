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

  # No op
  def filter(rows)
    rows
  end

  def records
    @records ||= self.filter data[self.class.rows]
  end

  # {
  #   :username => ["blah", "blah2", "blah3"],
  #   :role => ["admin", "owner", "owner"], ...
  # }
  def schema_records
    puts "  => generating schema records"
    Hash.new { |hash, key| hash[key] = [] }.tap do |h|
      total_records = self.records.size
      all_elapsed = Benchmark.realtime do
        self.class.schema.each do |column, value|
          elapsed = Benchmark.realtime do
            puts "    => column #{column.inspect}, value #{value.inspect}"
            h[column] = self.records.each_with_index.map do |record, i|
              print "\r       record #{i} of #{total_records} (#{(i*100.0/total_records).round}%)" if i % 5 == 0
              if record.respond_to? value
                record.send(value)
              else
                self.send(value, record, i)
              end
            end
          end
          puts "\n       Done. Elapsed time: #{elapsed} seconds"
        end
      end
      puts "     Done. Elapsed time: #{all_elapsed} seconds"
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
