require 'helper'

class TestAgrep < Test::Unit::TestCase
	def test_extend
		assert_equal 2, "aaba".extend(Agrep).aindex('ba')
		assert_equal 2, "aaba".extend(Agrep).aindex(/ba/)
	end

	def test_include
		String.send :include, Agrep

		assert_equal 2, "aaba".aindex('ba')
		assert_equal 2, "aaba".aindex(/ba/)
	end

	def test_aindex
	end
end
