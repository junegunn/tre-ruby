require 'helper'

class TestTRE < Test::Unit::TestCase
	def test_extend
		assert_equal 2...4, "aaba".extend(TRE).aindex('ba')
		assert_equal 2...4, "aaba".extend(TRE).aindex(/ba/)
	end

	def test_include
		String.send :include, TRE

		#1000000.times do
		assert_equal 2...4, "aaba".aindex('ba')
		assert_equal 2...4, "aaba".aindex(/ba/)
		#end
	end

	def test_aindex
	end
end
