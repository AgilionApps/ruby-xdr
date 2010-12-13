require 'rubygems'
require 'rake'

GEMSPEC = Gem::Specification.new do |s|
    s.name          = 'ruby-xdr'
    s.summary       = 'Ruby module to read and write XDR data'
    s.version       = File.read('VERSION').strip
    s.author        = 'Matthew Booth'
    s.email         = 'mbooth@redhat.com'
    s.files         = FileList['{lib,test}/*'].to_a.sort
    s.require_path  = 'lib'
    s.has_rdoc      = false
end
