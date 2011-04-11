require 'mkmf'

def x d
	abort "** #{d} is missing."
end

def xtre
	abort <<-MISSING
**
**
** TRE library is missing !!
** *************************
**
** You can download the source or the binaries from http://laurikari.net/tre/
**
** = e.g. To install TRE from the source code
**
**     tar -xvjf tre-0.8.0.tar.bz2
**     cd tre-0.8.0
**     ./configure
**     make
**     sudo make install
**
**
	MISSING
end

# TRE
xtre unless have_library('tre')
xtre unless have_header('tre/tre.h')

# Multi-byte support
# TRE_WCHAR
%w[TRE_MULTIBYTE TRE_APPROX].each do | macro |
	x "Macro #{macro}" unless have_macro macro, 'tre/tre.h'
end

create_makefile('tre-ruby/tre')

