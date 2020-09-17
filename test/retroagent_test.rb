# frozen_string_literal: true

require 'test_helper'

class RetroAgentTest < Minitest::Test
  def new_agent
    RetroAgent.new
  end

  def test_that_it_has_a_version_number
    refute { ::RetroAgent::VERSION.nil? }
  end

  def test_self
    assert { new_agent }
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
