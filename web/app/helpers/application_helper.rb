module ApplicationHelper
  def format_phone_number phone_number
    regexp = /^996(\d{3})(\d{6})/is
    matches = regexp.match phone_number
    if matches
      return "0-#{matches[1]}-#{matches[2]}"
    end
  end
end
