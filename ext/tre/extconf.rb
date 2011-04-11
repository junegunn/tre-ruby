require 'mkmf'

def x d
	abort "** #{d} is missing."
end

# TRE
x 'tre' unless have_library('tre')
x 'tre' unless have_header('tre/tre.h')

# Multi-byte support
# TRE_WCHAR
%w[TRE_MULTIBYTE TRE_APPROX].each do | macro |
	x "Macro #{macro}" unless have_macro macro, 'tre/tre.h'
end

create_makefile('tre-ruby/tre')

