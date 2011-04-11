$LOAD_PATH.unshift File.dirname(__FILE__) # FIXME
require 'helper'

class TestTRE < Test::Unit::TestCase
	class TREString < String
		include TRE
	end

	def test_extend
		assert_equal 2...4, "aaba".extend(TRE).aindex('ba')
		assert_equal [2...4], "aaba".extend(TRE).ascan_r(/ba/)
		assert_equal ["ba"], "aaba".extend(TRE).ascan(/ba/)
	end

	def test_include
		# String including TRE module would affect the subsequent tests
		# String.send :include, TRE

		# So, we use TREString here.
		str = TREString.new "aaba"
		assert_equal 2...4,   str.aindex('ba')
		assert_equal [2...4], str.ascan_r(/ba/)
		assert_equal ["ba"], str.ascan(/ba/)
	end

	def test_privacy
		str = TREString.new "aaba"
		assert_raise(NoMethodError) { str.__ascan 1,1,1,1,1,1,1 }
		assert_raise(NoMethodError) { str.__aindex 1,1,1,1,1,1 }
	end

	def test_aindex_string
		params = TRE::AParams.new

		# String patterns
		params.max_err = 1
		assert_equal 'would', TWISTER[ TWISTER.aindex('tould', 0, params) ]
		assert_equal nil, TWISTER.aindex('toult', 0, params)

		params.max_err = 2
		assert_equal 'would', TWISTER[ TWISTER.aindex('toult', 0, params) ]
		assert_equal 'could', TWISTER[ TWISTER.aindex('toult', 400, params) ]
	end

	def test_aindex_regex
		params = TRE::AParams.new

		# Regex pattenrs
		params.max_err = 1
		assert_equal 'would', TWISTER[ TWISTER.aindex /TOULD/i, 0, params ]
		assert_equal nil, TWISTER.aindex(/toult/i, 0, params)

		params.max_err = 2
		assert_equal nil, TWISTER.aindex(/TOULT/, 0, params)
		assert_equal 'would', TWISTER[ TWISTER.aindex(/TOULT/i, 0, params) ]
		assert_equal 'could', TWISTER[ TWISTER.aindex(/TOULT/i, 400, params) ]
		assert_equal 'could', TWISTER[ TWISTER.aindex(/TOULT/i, 400, params) ]
		assert_equal 'could', TWISTER[ TWISTER.aindex(/T((O)U(L))T/i, 400, params) ]
	end

	def test_aindex_mutable_default
		# Adjusting global default
		begin
			TRE::AParams.default.max_err = 2
			assert_equal nil, TWISTER.aindex(/TOULT/)
			assert_equal 'would', TWISTER[ TWISTER.aindex(/TOULT/i) ]
			assert_equal 'could', TWISTER[ TWISTER.aindex(/TOULT/i, 400) ]
			assert_equal 'could', TWISTER[ TWISTER.aindex(/TOULT/i, 400) ]
			assert_equal 'could', TWISTER[ TWISTER.aindex(/T((O)U(L))T/i, 400) ]
		ensure
			TRE::AParams.reset_default
			assert_equal 0, TRE::AParams.default.max_err
		end

		# Unsupported Regexp flag
		assert_raise(ArgumentError) { TWISTER.aindex(/TOULT/ix) }
	end

	def test_regex_flags
		# Test for case-insensitivity
		str = TREString.new "A\nB"
		assert_equal nil, str.aindex(/b/)
		assert_equal (2...3), str.aindex(/b/i)

		# Test for multiline
		assert_equal (0...1), str.aindex(/.*/)
		assert_equal (0...3), str.aindex(/.*/m)

		# Test for multiline and case-insensitivity
		assert_equal (0...1), str.aindex(/a.*?b?/i)
		assert_equal (0...3), str.aindex(/a.*?b?/im)

		# Test for unsupported x flag
		assert_raise(ArgumentError) { TWISTER.aindex(/a/x) }
	end

	def test_ascan_r
		result = TWISTER.ascan_r(/peck/, TRE::AParams.new { |ap| ap.max_err = 2 })
		assert_equal Array, result.class
		assert_equal Range, result.first.class

		result = TWISTER.ascan_r(/p(e)ck/, TRE::AParams.new { |ap| ap.max_err = 2 })
		assert_equal Array, result.class
		assert_equal Array, result.first.class
		assert_equal Range, result.first.first.class
		assert_equal Range, result.first.last.class
	end

	def test_ascan
		begin
			# Without blocks
			assert_equal 4, TWISTER.ascan(/peck/, TRE::AParams.new { |ap| ap.max_err = 0 }).length
			assert_equal 6, TWISTER.ascan(/peck/, TRE::AParams.new { |ap| ap.max_err = 1 }).length
			assert_equal 15, TWISTER.ascan(/peck/, TRE::AParams.new { |ap| ap.max_err = 2 }).length
			assert_equal 15, TWISTER.ascan(/(p(e)c)k/, TRE::AParams.new { |ap| ap.max_err = 2 }).length

			# Block given
			TWISTER.ascan(/peck/, TRE::AParams.new { |ap| ap.max_err = 2 }) do | a |
				assert a.is_a?(String)
			end
			TWISTER.ascan(/((p)e)ck/, TRE::AParams.new { |ap| ap.max_err = 2 }) do | a |
				assert a.is_a?(Array)
				assert_equal 2, a.length
			end
			TWISTER.ascan(/((p)e)ck/, TRE::AParams.new { |ap| ap.max_err = 2 }) do | a, b |
				assert a.is_a?(String)
				assert b.is_a?(String)
			end
		ensure
			TRE::AParams.reset_default
		end
	end

	TWISTER = TREString.new <<-EOF
		She sells sea shells by the sea shore.
		The shells she sells are surely seashells.
		So if she sells shells on the seashore,
		I'm sure she sells seashore shells.

		Peter Piper picked a peck of pickled peppers.
		Did Peter Piper pick a peck of pickled peppers?
		If Peter Piper picked a peck of pickled peppers,
		where's the peck of pickled peppers Peter Piper picked?

		How much wood would a woodchuck chuck
		if a woodchuck could chuck wood?
		He would chuck, he would, as much as he could,
		and chuck as much wood as a woodchuck would
		if a woodchuck could chuck wood.

		Betty Botter had some butter,
		"But," she said, "this butter's bitter.
		If I bake this bitter butter,
		it would make my batter bitter.
		But a bit of better butter--
		that would make my batter better."

		So she bought a bit of butter,
		better than her bitter butter,
		and she baked it in her batter,
		and the batter was not bitter.
		So 'twas better Betty Botter
		bought a bit of better butter.
	EOF
end
