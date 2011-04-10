# encoding: UTF-8

#$LOAD_PATH.unshift '.' # FIXME
require 'agrep/tre'

module Agrep
	# Returns Range
	def aindex regexp, offset = 0, params = Agrep::Params.default
		raise ArgumentError.new("Invalid parameter") unless params.is_a? Agrep::Params
		raise ArgumentError.new("Invalid offset parameter") unless offset.is_a? Fixnum

		input = parse_pattern regexp
		_aindex(input[:source], self, offset, params, input[:ignore_case], input[:multi_line])
	end
	
	# TODO
	def amatch regexp, offset = 0, params = Params.default
		raise NotImplementedError

		raise ArgumentError.new("Invalid parameter") unless params.is_a? Agrep::Params
		raise ArgumentError.new("Invalid offset parameter") unless offset.is_a? Fixnum

		if block_given?
			# yield match data
		else
		end
	end

	# TODO
	def ascan regexp, params = Params.default
		raise NotImplementedError

		raise ArgumentError.new unless params.is_a? Agrep::Params

		if block_given?
		else
		end
	end
	
	class Params
		attr_accessor :cost_ins  # Default cost of an inserted character.
		attr_accessor :cost_del  # Default cost of a deleted character.
		attr_accessor :cost_subst# Default cost of a substituted character.

		attr_accessor :max_cost  # Maximum allowed cost of a match.
		attr_accessor :max_ins   # Maximum allowed number of inserts.
		attr_accessor :max_del   # Maximum allowed number of deletes.
		attr_accessor :max_subst # Maximum allowed number of substitutes.
		attr_accessor :max_err   # Maximum allowed number of errors total.

		def self.default
			@@default ||= Agrep::Params.new.freeze
		end

		def self.default= nd
			raise ArgumentError.new('Not Agrep::Params object') unless nd.is_a? Agrep::Params

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

	class MatchData
		def initialize
		end

		def size
		end

		alias length size

		def [] idx
		end
	end

	def self.included base
		base.send :include, Agrep::TRE
	end

	def self.extended base
		base.extend Agrep::TRE
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
# 	puts "aaba".extend(Agrep).aindex('ba')

	class String
		include Agrep
	end

	params = Agrep::Params.new
	params.max_err = 1
	Agrep::Params.default = params
	
	str = "탐크루즈의 사이언톨로지"
	puts str.aindex(/크루스/i)
	puts str.aindex(/크루스/i)
	puts str[ str.aindex(/사이톨로/i) ]
end

