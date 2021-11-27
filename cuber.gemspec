require_relative 'lib/cuber/version'

Gem::Specification.new do |s|
  s.name = 'cuber'
  s.version = Cuber::VERSION
  s.summary = 'Cuber'
  s.author = 'Cuber'
  s.executables = ['cuber']
  s.files = ['bin/cuber', 'lib/cuber.rb']
  s.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com/cuber-cloud'
end
