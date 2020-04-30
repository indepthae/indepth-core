module ClassTimingsHelper
  def duration(class_timing)
    duration = Time.at((class_timing.end_time - class_timing.start_time).to_i.abs).utc.strftime("%H:%M:%S").split(":")
    duration_str = ""
    duration_str += "#{duration[0]} Hr " if duration[0].to_i > 0
    duration_str += "#{duration[1]} Min " if duration[1].to_i > 0
    duration_str += "#{duration[2]} Sec " if duration[2].to_i > 0
    return duration_str
  end
end
