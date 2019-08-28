class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.convert_reason(reason)
    reasons = {
      "insufficient-funds" => "Insufficient funds"
    }
    reasons[reason]
  end

  def self.to_money(unit)
    split = unit.to_s.chars
    if unit < 10
      "00.0" + unit.to_s
    elsif unit < 100
      "00." + unit.to_s
    else
      unit.to_s[0..-3] + "." +  unit.to_s[-2..-1]
    end
  end

  def self.trans_money(unit)
    split = unit.to_s.chars
    if unit < 10
      "00.0" + unit.to_s
    elsif unit < 100
      "00." + unit.to_s
    else
      unit.to_s[0..-3] + "." +  unit.to_s[-2..-1]
    end
  end

  def self.to_pretty(time)
    a = (Time.now - time).to_i
    case a
      when 0 then 'just now'
      when 1 then 'a second ago'
      when 2..59 then a.to_s+' seconds ago'
      when 60..119 then 'a minute ago' #120 = 2 minutes
      when 120..3540 then (a/60).to_i.to_s+' minutes ago'
      when 3541..7100 then 'an hour ago' # 3600 = 1 hour
      when 7101..82800 then ((a+99)/3600).to_i.to_s+' hours ago'
      when 82801..172000 then 'a day ago' # 86400 = 1 day
      when 172001..518400 then ((a+800)/(60*60*24)).to_i.to_s+' days ago'
      else time.strftime("%x")
    end
  end

  def self.to_initials(name)
    split = name.split.map { |word| word.chars.first.upcase }
    split.length > 2 ? split[0] + split[-1] : split.join
  end

  def self.to_sort(number)
    string = number.to_s.chars
    "#{string[0..1].join}-#{string[2..3].join}-#{string[4..5].join}"
  end
end
