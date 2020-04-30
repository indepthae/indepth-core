Object.class_eval do
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end
end