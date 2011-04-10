# encoding: UTF-8

#$LOAD_PATH.unshift '.' # FIXME
require 'tre/tre'

module TRE
	# Returns Range
	def aindex regexp, offset = 0, params = TRE::AParams.default
		raise ArgumentError.new("Invalid parameter") unless params.is_a? TRE::AParams
		raise ArgumentError.new("Invalid offset parameter") unless offset.is_a? Fixnum

		input = parse_pattern regexp
		_aindex(input[:source], self, offset, params, input[:ignore_case], input[:multi_line])
	end
	
	# TODO
	def amatch regexp, offset = 0, params = AParams.default
		raise NotImplementedError

		raise ArgumentError.new("Invalid parameter") unless params.is_a? TRE::AParams
		raise ArgumentError.new("Invalid offset parameter") unless offset.is_a? Fixnum

		if block_given?
			# yield match data
		else
		end
	end

	# TODO
	def ascan regexp, params = AParams.default
		raise NotImplementedError

		raise ArgumentError.new unless params.is_a? TRE::AParams

		if block_given?
		else
		end
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

		def self.default
			@@default ||= TRE::AParams.new.freeze
		end

		def self.default= nd
			raise ArgumentError.new('Not TRE::AParams object') unless nd.is_a? TRE::AParams

			@@default = nd
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
			raise ArgumentError("x flag not supported") if (opts & Regexp::EXTENDED) > 0
			ret[:multi_line] = (opts & Regexp::MULTILINE) > 0
			ret[:ignore_case] = (opts & Regexp::IGNORECASE) > 0
		when String
			ret[:source] = Regexp.escape pattern
		end

		ret
	end
end

if __FILE__ == $0
	class String
		include TRE
	end

	params = TRE::AParams.new
	params.max_err = 1
	TRE::AParams.default = params
	
	str = "탐크루즈의 사이언톨로지"
	puts str.aindex(/크루스/i)
	puts str.aindex(/크루스/i)
	puts str[ str.aindex(/사이톨로/i) ]
end

