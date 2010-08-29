def init
  super
  return unless defined? $DISQUS
  sections.push :disqus
end