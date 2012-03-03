class DateUtil
  def self.latest_weekday_before(date)
    case date.wday
    when 0
      return date - 2
    when 6
      return date - 1
    else
      return date.clone
    end
  end
end
