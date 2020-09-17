# frozen_string_literal: true

require 'nkf'
require 'mechanize'

class RetroAgent
  module UTF8
    module_function

    def encode(str, encoding = nil)
      encoding = NKF.guess(str) unless encoding.is_a?(Encoding) || encoding.is_a?(String)
      str.dup.force_encoding(encoding).encode(Encoding::UTF_8)
    end

    def page(page, encoding = nil)
      case page
      when Mechanize::Page
        page.class.new(page.uri, page.response, encode(page.body, encoding), page.code, page.mech)
      when Mechanize::File
        page.class.new(page.uri, page.response, encode(page.body, encoding), page.code)
      else
        raise NotImplementedError, "#{page.class} isn't supported"
      end
    end
  end
end
