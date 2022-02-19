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
  s.add_dependency 'jwt'
end
