def init
  super
  return unless defined? $CONFIG.disqus
  sections.push :disqus
end