def init
  super
  return unless defined? Rubydoc.config.disqus
  sections.push :disqus
end
