require 'date'

class Date
  def last_weekday
    case self.wday
    when 0
      return self - 2
    when 6
      return self - 1
    else
      return self.clone
    end
  end
end
