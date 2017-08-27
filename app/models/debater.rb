class Debater < ApplicationRecord
  belongs_to :school

  def code_letter
    last_name[0]
  end

  def name
    "#{first_name} #{last_name}"
  end
end
