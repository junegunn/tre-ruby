# encoding: UTF-8

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
		#   String.send :include, TRE
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

	def test_aparams
		aparams = TRE::AParams.new
		assert_equal 0, aparams.max_err
		aparams.max_err = 5
		assert_equal 5, aparams.max_err
	end

	def test_fuzziness
		fuzz1 = TRE.fuzziness 1
		assert_equal TRE::AParams, fuzz1.class
		assert_equal 1, fuzz1.max_err
		assert fuzz1.frozen?

		fuzz2 = TRE.fuzziness 2
		assert_equal TRE::AParams, fuzz2.class
		assert_equal 2, fuzz2.max_err
		assert fuzz2.frozen?

		# Same frozen object for same fuzziness
		assert_equal fuzz1.object_id, TRE.fuzziness(1).object_id
		assert_equal fuzz2.object_id, TRE.fuzziness(2).object_id
		assert_not_equal fuzz1.object_id, fuzz2.object_id
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
		params = TRE.fuzziness 1

		# Regex pattenrs
		assert_equal 'would', TWISTER[ TWISTER.aindex /TOULD/i, 0, params ]
		assert_equal nil, TWISTER.aindex(/toult/i, 0, params)

		# Frozen: cannot modify
		assert_raise(RUBY_VERSION =~ /^1.8/ ? TypeError : RuntimeError) { params.max_err = 2 }

		# Warm AParams
		params = TRE::AParams.new
		params.max_err = 2

		assert_equal nil, TWISTER.aindex(/TOULT/, 0, params)
		assert_equal 'would', TWISTER[ TWISTER.aindex(/TOULT/i, 0, params) ]
		assert_equal 'could', TWISTER[ TWISTER.aindex(/TOULT/i, 400, params) ]
		assert_equal 'could', TWISTER[ TWISTER.aindex(/TOULT/i, 400, params) ]
		assert_equal 'could', TWISTER[ TWISTER.aindex(/T((O)U(L))T/i, 400, params) ]

		# afind shortcut
		assert_equal 'would', TWISTER.afind(/TOULT/i, 0, params)
		assert_equal 'could', TWISTER.afind(/TOULT/i, 400, params)
		assert_equal 'could', TWISTER.afind(/TOULT/i, 400, params)
		assert_equal 'could', TWISTER.afind(/T((O)U(L))T/i, 400, params)
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
		result = TWISTER.ascan_r(/peck/, TRE.fuzziness(2))
		assert_equal Array, result.class
		assert_equal Range, result.first.class

		result = TWISTER.ascan_r(/p(e)ck/, TRE.fuzziness(2)) 
		assert_equal Array, result.class
		assert_equal Array, result.first.class
		assert_equal Range, result.first.first.class
		assert_equal Range, result.first.last.class
	end

	def test_ascan
		# Without blocks
		assert_equal 4, TWISTER.ascan(/peck/,      TRE.fuzziness(0)).length
		assert_equal 6, TWISTER.ascan(/peck/,      TRE.fuzziness(1)).length
		assert_equal 15, TWISTER.ascan(/peck/,     TRE.fuzziness(2)).length
		assert_equal 15, TWISTER.ascan(/(p(e)c)k/, TRE.fuzziness(2)).length

		# Block given
		TWISTER.ascan(/peck/, TRE.fuzziness(2)) do | a |
			assert a.is_a?(String)
		end
		TWISTER.ascan(/((p)e)ck/, TRE.fuzziness(2)) do | a |
			assert a.is_a?(Array)
			assert_equal 2, a.length
		end
		TWISTER.ascan(/((p)e)ck/, TRE.fuzziness(2)) do | a, b |
			assert a.is_a?(String)
			assert b.is_a?(String)
		end
	end

	def test_asub
		assert_equal 1, TWISTER.asub(/(pe)(ck)/, '\2\2\1\1', TRE.fuzziness(3)).scan('ckckpepe').length
	end

	def test_asub!
		copy = TWISTER.dup
		rep = TWISTER.asub(/(pe)(ck)/, '\2\2\1\1', TRE.fuzziness(3))
		copy.         asub!(/(pe)(ck)/, '\2\2\1\1', TRE.fuzziness(3))

		assert_equal copy, rep
		assert_not_equal copy, TWISTER
	end

	def test_agsub
		assert_equal 15, TWISTER.ascan(/(pe)(ck)/, TRE.fuzziness(2)).length
		assert_equal 4, TWISTER.ascan(/(pe)(ck)/, TRE.fuzziness(2)).select { |m| m[0] == 'peck' }.length
		assert_equal 4, TWISTER.agsub(/(pe)(ck)/, '\2\2\1\1', TRE.fuzziness(2)).scan('ckckpepe').length

		# TODO: More rigorous tests
	end

	def test_agsub!
		copy = TWISTER.dup
		rep = TWISTER.agsub(/(pe)(ck)/, '\2\2\1\1', TRE.fuzziness(3))
		copy.         agsub!(/(pe)(ck)/, '\2\2\1\1', TRE.fuzziness(3))

		assert_equal copy, rep
		assert_not_equal copy, TWISTER
	end

	def test_multibyte
		$KCODE = 'u' if RUBY_VERSION =~ /^1.8/
		lyric = "
			사랑을 한다는 말은 못했어
			어쨌거나 지금은 너무 늦어버렸어
			그때 나는 무얼 하고 있었나
			그 미소는 너무 아름다웠어
			난 정말 그대 그대만을 좋아헀어
			나에게 이런 슬픔 안겨 주는 그대여
			제발 이별만은 말 하지 말아요
			나에겐 오직 그대만이 전부였잖아
			오 그대여 가지 마세요
			나를 정말 떠나 가나요
			오 그대여 가지 마세요
			나는 지금 울잖아요
			난 알아요
			이 밤이 흐르면 YO!
			그대 떠나는 모습 뒤로 하고
			마지막 키스에 슬픈 마음
			정말 떠나는가
			사랑을 하고 싶어 너의 모든 향기
			내 몸 속에 젖어 있는 너의 많은 숨결
			그 미소 그 눈물 그 알 수 없는 마음 그대 마음
			그리고 또 마음 그대 마음
			그 어렵다는 편지는 쓰지 않아도 돼
			너의 진실한 모습을 바라보고 있어요
			아직도 마음속엔 내가 있나요
			나는 그대의 영원한
			난 정말 그대 그대만을 좋아했어
			나에게 이런 슬픔 안겨주는 그대여
			오 그대여 가지 마세요
			나를 정말 떠나 가나요
			오 그대여 가지 마세요
			나는 지금 울잖아요
			오 그대여 가지 마세요
			나를 정말 떠나 가나요
			오 그대여 가지 마세요
			나는 지금 울잖아요"
		srch = "오 그대여 가지 마세요"
		assert_equal 6,
			lyric.extend(TRE).ascan_r(/#{srch}/i, TRE.fuzziness(0)).length
		assert_equal 6,
			lyric.extend(TRE).ascan(/#{srch}/i, TRE.fuzziness(0)).length
		assert lyric.extend(TRE).ascan(/#{srch}/i, TRE.fuzziness(0)).all? { |e| e == srch }
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
