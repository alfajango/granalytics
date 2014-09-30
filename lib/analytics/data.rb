class Analytics::Data < Hash

  def initialize(granularity, range, lookup_keys, results)
    self[:granularity] = granularity
    self[:range] = range
    self[:lookup_keys] = lookup_keys
    self[:results] = results
  end

  def decorate!(&block)
    self[:results].each do |result|
      yield result
    end
  end

end
