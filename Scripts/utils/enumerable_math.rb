# Modified version of http://stackoverflow.com/a/7749613/210780
# variance divides by length, not length - 1
module Enumerable
  def sum
    self.inject(0) { |accum, i| accum + i }
  end

  def mean
    self.sum / self.length.to_f
  end

  def variance
    m = self.mean
    sum = self.inject(0) { |accum, i| accum + (i-m)**2 }
    sum.to_f / self.length
  end

  def standard_deviation
    return Math.sqrt(self.variance)
  end
end