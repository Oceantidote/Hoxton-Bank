class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  def self.convert_reason(reason)
    reasons = {
      "insufficient-funds" => "Insufficient funds"
    }
    reasons[reason]
  end
end
