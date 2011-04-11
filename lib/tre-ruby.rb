# encoding: UTF-8

$LOAD_PATH.unshift '.' #FIXME
require 'tre-ruby/tre'

module TRE
	# Returns a TRE::AParams object with given fuzziness (max_err)
	def TRE.fuzziness max_err
		@@fuzzies ||= {}
		return @@fuzzies[max_err] if @@fuzzies.has_key? max_err

		param = TRE::AParams.new
		param.max_err = max_err
		param.freeze
		@@fuzzies[max_err] = param
	end

	# Returns Range
	def aindex pattern, offset = 0, params = TRE.fuzziness(0)
		raise ArgumentError.new("Invalid parameter") unless params.is_a? TRE::AParams
		raise ArgumentError.new("Invalid offset parameter") unless offset.is_a? Fixnum

		input = parse_pattern pattern
		__aindex(input[:source], self, offset, params, 
				input[:ignore_case], input[:multi_line])
	end

	# Returns the first match as a String
	def afind pattern, offset = 0, params = TRE.fuzziness(0)
		range = aindex pattern, offset, params

		range && self[range]
	end

	# Returns Array of Ranges
	def ascan_r pattern, params = TRE.fuzziness(0), &block
		ascan_r_impl pattern, params, true, &block
	end

	# Returns Array of Substrings
	def ascan pattern, params = TRE.fuzziness(0), &block
		result = ascan_r(pattern, params).map { |e|
			case e
			when Array
				e.map { |ee| self[ee] }.take_while { |ee| ee }
			when Range
				self[e]
			else
				raise RuntimeError.new
			end
		}
		return result unless block_given?
		yield_scan_result result, &block
	end
	
	def asub pattern, replacement, params = TRE.fuzziness(0), &block
		asub_impl pattern, replacement, params, false, &block
	end

	def agsub pattern, replacement, params = TRE.fuzziness(0), &block
		asub_impl pattern, replacement, params, true, &block
	end

	# Parameters for approximate matching.
	class AParams
		# Default cost of an inserted character.
		attr_accessor :cost_ins  
		# Default cost of a deleted character.
		attr_accessor :cost_del  
		# Default cost of a substituted character.
		attr_accessor :cost_subst

		# Maximum allowed cost of a match.
		attr_accessor :max_cost
		# Maximum allowed number of inserts.
		attr_accessor :max_ins
		# Maximum allowed number of deletes.
		attr_accessor :max_del
		# Maximum allowed number of substitutes.
		attr_accessor :max_subst
		# Maximum allowed number of errors total.
		attr_accessor :max_err

		# Creates a AParams object with default values
		def initialize
			self.cost_ins = 1
			self.cost_del = 1
			self.cost_subst = 1
			self.max_cost = nil
			self.max_ins = nil
			self.max_del = nil
			self.max_del = nil
			self.max_subst = nil
			self.max_err = 0

			yield self if block_given?
		end
	end

	# TODO
	def amatch pattern, offset = 0, params = TRE.fuzziness(0)
		raise NotImplementedError

		raise ArgumentError.new("Invalid parameter") unless params.is_a? TRE::AParams
		raise ArgumentError.new("Invalid offset parameter") unless offset.is_a? Fixnum
	end
private
	def parse_pattern pattern
		ret = {}
		case pattern
		when Regexp
			ret[:source] = pattern.source

			opts = pattern.options
			ret[:multi_line] = (opts & Regexp::MULTILINE) > 0
			opts &= ~Regexp::MULTILINE
			ret[:ignore_case] = (opts & Regexp::IGNORECASE) > 0
			opts &= ~Regexp::IGNORECASE
			raise ArgumentError.new("Unsupported Regexp flag provided") if opts > 0

			# Pessimistic estimation of the number of captures
			ret[:num_captures] = ret[:source].each_char.count { |c| c == '(' }
		when String
			ret[:source] = Regexp.escape pattern
			ret[:num_captures] = 0
		end

		ret
	end

	def ascan_r_impl pattern, params, repeat, &block
		raise ArgumentError.new("Invalid parameter") unless params.is_a? TRE::AParams

		input = parse_pattern pattern
		result = __ascan(input[:source], self, 0, params, 
				input[:ignore_case], input[:multi_line], input[:num_captures], repeat)

		return result unless block_given?
		yield_scan_result result, &block
	end

	def asub_impl pattern, replacement, params, repeat, &block
		raise NotImplementedError.new if block_given?
		raise NotImplementedError.new unless replacement.is_a? String

		ret = self.dup

		ascan_r_impl(pattern, params, repeat, &block).each do | ranges |
			# Captures
			if ranges.is_a? Array
				repl = replacement.dup
				ranges[1..-1].each_with_index do | range, idx |
					repl.gsub!("\\#{idx + 1}", self[range])
				end
				ret[ranges[0]] = repl
			else
				ret[ranges] = replacement
			end
		end

		ret
	end

	def yield_scan_result result, &block
		return self if result.empty?

		# With captures
		if result.first.is_a?(Array)
			# arity == 1
			if block.arity == 1
				result.each { |r| yield r[1..-1] }
			else
				result.each { |r| yield *r[1..-1] }
			end
		# Without captures
		else
			result.each { |r| yield r }
		end
		self
	end
end

