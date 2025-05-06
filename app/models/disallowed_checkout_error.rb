class DisallowedCheckoutError < StandardError
  def initialize(owner:, project:)
    super("Invalid checkout for #{owner}/#{project}")
  end
end
