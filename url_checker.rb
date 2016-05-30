require 'rubygems'
require 'bundler/setup'
require 'uri'
require 'resolv'

Bundler.require(:default)

class UrlChecker
  private_class_method :new

  def self.call(url)
    url = "http://#{url}" unless url.match(/^https?:\/\//)
    new(url).call
  end

  def call
    return false unless fulfills_requirements?
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue
    false
  end

  private

  attr_reader :url

  def initialize(url)
    @url = url
  end

  def fulfills_requirements?
    [url, domain_exists?, remote_url_exist?, uri_opens?].all?
  end

  def remote_url_exist?
    domain = domain_name
    Resolv.getaddress(domain)
  rescue
    false
  end

  def domain_exists?
    domain = domain_name
    Socket.gethostbyname(domain.to_s)
    true
  rescue SocketError
    false
  end

  def domain_name
    uri = URI.parse(URI.encode(url))
    uri = URI.parse("http://#{url}") if uri.scheme.nil?
    return unless uri.host
    host = uri.host.downcase
    host.start_with?('www.') ? host[4..-1] : host
  end

  def uri_opens?
    open(url, open_timeout: 5, allow_redirections: :all)
  rescue
    false
  end
end

puts "Checking url #{ARGV[0]}.... #{UrlChecker.call(ARGV[0]) ? 'VALID!' : 'INVALID!'}"
