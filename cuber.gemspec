require_relative 'lib/cuber/version'

Gem::Specification.new do |s|
  s.name = 'cuber'
  s.version = Cuber::VERSION
  s.summary = 'Deploy your apps on Kubernetes easily.'
  s.author = 'Cuber'
  s.homepage = 'https://cuber.cloud'
  s.license = 'LicenseRef-LICENSE.md'
  s.executables = ['cuber']
  s.files = `git ls-files`.split("\n")
  s.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com/cuber-cloud'
  s.add_dependency 'jwt'
end
