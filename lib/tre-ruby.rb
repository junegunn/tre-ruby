# encoding: UTF-8

$LOAD_PATH.unshift '.' #FIXME
require 'tre-ruby/tre'

module TRE
	# Returns Range
	def aindex regexp, offset = 0, params = TRE::AParams.default
		raise ArgumentError.new("Invalid parameter") unless params.is_a? TRE::AParams
		raise ArgumentError.new("Invalid offset parameter") unless offset.is_a? Fixnum

		input = parse_pattern regexp
		__aindex(input[:source], self, offset, params, 
				input[:ignore_case], input[:multi_line])
	end

	# Returns Array of Ranges
	def ascan_r regexp, params = AParams.default, &block
		raise ArgumentError.new("Invalid parameter") unless params.is_a? TRE::AParams

		input = parse_pattern regexp
		result = __ascan(input[:source], self, 0, params, 
				input[:ignore_case], input[:multi_line], input[:num_captures])

		return result unless block_given?
		yield_scan_result result, &block
	end

	# Returns Array of Substrings
	def ascan regexp, params = AParams.default, &block
		result = ascan_r(regexp, params).map { |e|
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
	
	# TODO
	def amatch regexp, offset = 0, params = AParams.default
		raise NotImplementedError

		raise ArgumentError.new("Invalid parameter") unless params.is_a? TRE::AParams
		raise ArgumentError.new("Invalid offset parameter") unless offset.is_a? Fixnum
	end
	
	# Parameters for approximate matching.
	class AParams
		attr_accessor :cost_ins  # Default cost of an inserted character.
		attr_accessor :cost_del  # Default cost of a deleted character.
		attr_accessor :cost_subst# Default cost of a substituted character.

		attr_accessor :max_cost  # Maximum allowed cost of a match.
		attr_accessor :max_ins   # Maximum allowed number of inserts.
		attr_accessor :max_del   # Maximum allowed number of deletes.
		attr_accessor :max_subst # Maximum allowed number of substitutes.
		attr_accessor :max_err   # Maximum allowed number of errors total.

		# Caution: Adjusting the default AParams object makes the code not thread-safe!
		def self.default
			@@default ||= TRE::AParams.new
		end

		def self.reset_default
			@@default = TRE::AParams.new
		end

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
	def asub
		raise NotImplementedError
	end

	# TODO
	def agsub
		raise NotImplementedError
	end
private
	def parse_pattern pattern
		ret = {}
		case pattern
		when Regexp
			ret[:source] = pattern.source

			opts = pattern.options

			# Not supported
			raise ArgumentError.new("x flag not supported") if (opts & Regexp::EXTENDED) > 0
			ret[:multi_line] = (opts & Regexp::MULTILINE) > 0
			ret[:ignore_case] = (opts & Regexp::IGNORECASE) > 0

			# Pessimistic estimation of the number of captures
			ret[:num_captures] = ret[:source].each_char.count { |c| c == '(' }
		when String
			ret[:source] = Regexp.escape pattern
			ret[:num_captures] = 0
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

