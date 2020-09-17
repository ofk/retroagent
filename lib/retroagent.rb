# frozen_string_literal: true

require 'retroagent/version'
require 'retroagent/utf8'

require 'forwardable'
require 'tinytyping'
require 'mechanize'

class RetroAgent
  extend Forwardable
  include TinyTyping

  attr_reader :mech

  typed [String, Encoding, true, nil]
  attr_accessor :encoding

  typed Array
  attr_accessor :error_skip_statuses

  typed Array
  attr_accessor :retry_statuses

  typed Numeric
  attr_accessor :retry_interval

  typed Integer
  attr_accessor :retry_limit

  def initialize
    @mech = Mechanize.new
    self.error_skip_statuses = []
    self.retry_statuses = []
    self.retry_interval = 60
    self.retry_limit = 10
    self.user_agent = 'Mac Firefox'
  end

  def_delegators :mech, 'log', 'log=', 'user_agent'

  def user_agent=(ua)
    mech.user_agent_alias = ua
  rescue ArgumentError
    mech.user_agent = ua
  end

  def option(options = {})
    original_options = {}
    options.each_key { |key| original_options[key] = send(key) }
    options.each { |key, val| send("#{key}=", val) }
    return self unless block_given?
    yield
    original_options.each { |key, val| send("#{key}=", val) }
    nil
  end

  def get(uri, parameters = [], headers = {}, &block)
    request(:get, uri, parameters, uri, headers, &block)
  end

  %i[delete head post put].each do |method|
    define_method(method) do |*args, &block|
      request(method, *args, &block)
    end
  end

  private

  def request(*args)
    error_skip_statuses.map!(&:to_s)
    retry_statuses.map!(&:to_s)
    count = retry_limit
    page = begin
             count -= 1
             mech.send(*args)
           rescue Mechanize::ResponseCodeError => e
             if error_skip_statuses.include?(e.response_code)
               e.page
             elsif retry_statuses.include?(e.response_code) && count > 0
               sleep retry_interval
               retry
             else
               raise e
             end
           end
    page = UTF8::page(page, encoding) if encoding
    page
  end
end
