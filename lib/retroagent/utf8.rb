# frozen_string_literal: true

require 'nkf'

module RetroAgent
  module UTF8
    module_function

    def encode(str, encoding = nil)
      encoding = NKF.guess(str) unless encoding.is_a?(Encoding) || encoding.is_a?(String)
      str.dup.force_encoding(encoding).encode(Encoding::UTF_8)
    end
  end
end
