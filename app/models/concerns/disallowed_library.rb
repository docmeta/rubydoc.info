module DisallowedLibrary
  extend ActiveSupport::Concern

  def disallowed?
    disallowed_list.any? { |disallowed_name| wilcard_match?(name, disallowed_name) }
  end

  def disallowed_list
    []
  end

  def wilcard_match?(name, disallowed_name)
    return true if name == disallowed_name
    return true if disallowed_name == "*"

    regex = Regexp.new(disallowed_name.gsub("*", ".*"))
    regex.match?(name)
  end
end
