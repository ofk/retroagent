# frozen_string_literal: true

require 'test_helper'
require 'benchmark'

class RetroAgentTest < Minitest::Test
  def new_agent
    RetroAgent.new.tap do |agent|
      agent.log = Logger.new(STDERR)
      agent.log.level = Logger::FATAL
    end
  end

  def test_that_it_has_a_version_number
    refute { ::RetroAgent::VERSION.nil? }
  end

  def test_self
    assert { new_agent }
  end

  def test_get
    assert { new_agent.get('http://httpstat.us/200').body == '200 OK' }

    assert_raises Mechanize::ResponseCodeError do
      new_agent.get('http://httpstat.us/404')
    end

    new_agent.tap do |agent|
      agent.error_skip_statuses = [404]
      assert { agent.get('http://httpstat.us/404').body == '404 Not Found' }
    end

    assert_raises Mechanize::ResponseCodeError do
      new_agent.get('http://httpstat.us/503')
    end

    # slow test
    new_agent.tap do |agent|
      agent.retry_statuses = [503]
      agent.retry_interval = 1
      agent.retry_limit = 3
      time = Benchmark.realtime do
        assert_raises Mechanize::ResponseCodeError do
          agent.get('http://httpstat.us/503')
        end
      end
      assert { time >= agent.retry_interval * (agent.retry_limit - 1) }
    end
  end

  def test_option
    # cf. http://tools.m-bsys.com/ex/html-mojibake.php
    origin = "\u3042\u3044\u3046\u3048\u304a\uff10\uff11\uff12\uff13\uff41\uff42\uff43\uff38\uff39\uff3a\uff71\uff72\uff73\uff74\uff75\uff67\uff68\uff69\uff6a\u30a9\u6587\u5b57\u5316\u3051\u30d1\u30bf\u30fc\u30f3\u6a5f\u80fd\u30fb\u7814\u7a76\uff5e\u2015\uff0d\uff04\uffe0\uffe1\u3231\u2460\u2161"
    encoded = "\u3042\u3044\u3046\u3048\u304a\uff10\uff11\uff12\uff13\uff41\uff42\uff43\uff38\uff39\uff3a\uff71\uff72\uff73\uff74\uff75\uff67\uff68\uff69\uff6a\u30a9\u6587\u5b57\u5316\u3051\u30d1\u30bf\u30fc\u30f3\u6a5f\u80fd\u30fb\u7814\u7a76\u301c\u2015\u2212\uff04\u00a2\u00a3\u3231\u2460\u2161"

    gettext = proc { |url, encoding| new_agent.option(encoding: encoding).get(url).at('body').text.gsub(/\s+/, '').strip }
    genurl = proc { |real, virtual| "http://tools.m-bsys.com/img/mojibake/#{real}-#{virtual}.html" }

    assert { gettext.call(genurl.call('UTF8', 'UTF8')).to_s == origin }
    assert { gettext.call(genurl.call('UTF8', 'SJIS')).to_s == origin }
    assert { gettext.call(genurl.call('UTF8', 'EUC')).to_s == origin }
    assert { gettext.call(genurl.call('SJIS', 'UTF8')).to_s == encoded }
    assert { gettext.call(genurl.call('SJIS', 'SJIS')).to_s == encoded }
    assert { gettext.call(genurl.call('SJIS', 'EUC')).to_s == encoded }
    assert { gettext.call(genurl.call('EUC', 'UTF8'), true).to_s == origin }
    assert { gettext.call(genurl.call('EUC', 'SJIS'), true).to_s == origin }
    assert { gettext.call(genurl.call('EUC', 'EUC'), true).to_s == origin }
  end

  def test_utf8_encode
    str = "a-z\u3041-\u3093\u30a1-\u30f6\u4e9c-\u7199\u2460"
    assert { RetroAgent::UTF8.encode(str) == str }

    [
      Encoding::UTF_8,
      Encoding::CP932,
      Encoding::CP51932
    ].each do |to_encoding|
      encoded_str = str.encode(to_encoding)
      binary_str = encoded_str.dup
      binary_str.force_encoding(Encoding::BINARY)
      assert { RetroAgent::UTF8.encode(encoded_str) == str }
      assert { RetroAgent::UTF8.encode(binary_str) == str }
    end
  end
end
