#include "ruby.h"
#include "tre/tre.h"

VALUE mTRE;

#define _TRE_RUBY_APARAM_OVERRIDE(P) \
	VALUE P = rb_funcall(params, rb_intern(#P), 0); \
	if (P != Qnil) aparams->P = NUM2INT(P)
static void
tre_build_aparams(regaparams_t* aparams, VALUE params) {
	// Sets to default
	tre_regaparams_default(aparams);

	// Then override
	_TRE_RUBY_APARAM_OVERRIDE(cost_ins);
	_TRE_RUBY_APARAM_OVERRIDE(cost_del);
	_TRE_RUBY_APARAM_OVERRIDE(cost_subst);
	_TRE_RUBY_APARAM_OVERRIDE(max_cost);
	_TRE_RUBY_APARAM_OVERRIDE(max_ins);
	_TRE_RUBY_APARAM_OVERRIDE(max_del);
	_TRE_RUBY_APARAM_OVERRIDE(max_subst);
	_TRE_RUBY_APARAM_OVERRIDE(max_err);
}
#undef _TRE_RUBY_APARAM_OVERRIDE

static void
tre_compile_regex(regex_t* preg, VALUE pattern, VALUE ignore_case, VALUE multi_line) {
	Check_Type(pattern, T_STRING);

	int cflags = REG_EXTENDED;
	if (ignore_case == Qtrue) cflags = cflags | REG_ICASE;
	if (multi_line == Qfalse) cflags = cflags | REG_NEWLINE;

	reg_errcode_t result = tre_regncomp(preg, StringValuePtr(pattern), RSTRING_LEN(pattern), cflags);

	if (result == REG_OK) return;

	switch (result) {
		case REG_NOMATCH:
			rb_raise(rb_eRuntimeError, "No match.");
			break;
		case REG_BADPAT:
			rb_raise(rb_eRuntimeError, "Invalid regexp.");
			break;
		case REG_ECOLLATE:
			rb_raise(rb_eRuntimeError, "Unknown collating element.");
			break;
		case REG_ECTYPE:
			rb_raise(rb_eRuntimeError, "Unknown character class name.");
			break;
		case REG_EESCAPE:
			rb_raise(rb_eRuntimeError, "Trailing backslash.");
			break;
		case REG_ESUBREG:
			rb_raise(rb_eRuntimeError, "Invalid back reference.");
			break;
		case REG_EBRACK:
			rb_raise(rb_eRuntimeError, "\"[]\" imbalance");
			break;
		case REG_EPAREN:
			rb_raise(rb_eRuntimeError, "\"\\(\\)\" or \"()\" imbalance");
			break;
		case REG_EBRACE:
			rb_raise(rb_eRuntimeError, "\"\\{\\}\" or \"{}\" imbalance");
			break;
		case REG_BADBR:
			rb_raise(rb_eRuntimeError, "Invalid content of {}");
			break;
		case REG_ERANGE:
			rb_raise(rb_eRuntimeError, "Invalid use of range operator");
			break;
		case REG_ESPACE:
			rb_raise(rb_eRuntimeError, "Out of memory.");
			break;
		case REG_BADRPT:
           	rb_raise(rb_eRuntimeError, "Invalid use of repetition operators.");
			break;
		default:
			rb_raise(rb_eRuntimeError, "Unknown Error");
			break;
	}
}

static VALUE
tre_traverse(VALUE pattern, VALUE string, long char_offset, VALUE params,
		VALUE ignore_case, VALUE multi_line, int num_captures, VALUE repeat) {

	// Compile once
	regex_t preg;
	tre_compile_regex(&preg, pattern, ignore_case, multi_line);

	// Build regaparams
	regaparams_t aparams;
	tre_build_aparams(&aparams, params);

	// Match data
	regamatch_t match;
	regmatch_t pmatch[num_captures + 1];
	// memset(&match, 0, sizeof(match));
	match.nmatch = num_captures + 1;
	match.pmatch = pmatch;

	// Scan
	VALUE arr = rb_ary_new();
	long char_offset_acc = char_offset;
	// rb_global_variable(&arr);

	while (1) {
		// Get substring to start with
		long len = RSTRING_LEN(string) - char_offset;
		if (char_offset >= len) break;
		string = rb_str_substr(string, char_offset, len);

		int result = tre_reganexec(&preg, StringValuePtr(string), len, &match, aparams, 0);

		if (result == REG_NOMATCH) break;

		// Fill in array with ranges
		VALUE subarr;
		if (match.nmatch == 1) 
			subarr = arr;	// Fake
		else {
			subarr = rb_ary_new();
			// rb_global_variable(&subarr);
		}

		unsigned int i;
		for (i = 0; i < match.nmatch; ++i)
			if (match.pmatch[i].rm_so == -1)
				rb_ary_push(subarr, Qnil);
			else {
				VALUE range = rb_range_new(
						LONG2NUM( char_offset_acc + rb_str_sublen(string, match.pmatch[i].rm_so) ),
						LONG2NUM( char_offset_acc + rb_str_sublen(string, match.pmatch[i].rm_eo) ),
						1);
				// rb_global_variable(&range);

				rb_ary_push(subarr, range);
			}
		if (match.nmatch > 1) rb_ary_push(arr, subarr);

		// Stop or proceed
		if (repeat == Qfalse)
			break;
		else {
			char_offset = rb_str_sublen(string, match.pmatch[0].rm_eo);
			if (char_offset == 0) char_offset = 1; // Weird case
			char_offset_acc += char_offset;
		}
	}

	// Free once
	tre_regfree(&preg);

	return arr;
}

static VALUE
tre_aindex(int argc, VALUE *argv, VALUE self) {
	VALUE pattern, string, char_offset, params, ignore_case, multi_line;
	rb_scan_args(argc, argv, "60", &pattern, &string, &char_offset, &params, &ignore_case, &multi_line);

	Check_Type(string, T_STRING);

	VALUE rarray = tre_traverse(pattern, string, NUM2LONG(char_offset), params,
			ignore_case, multi_line, 0, Qfalse);

	if (RARRAY_LEN(rarray) == 0)
		return Qnil;
	else
		return rb_ary_entry(rarray, 0);
}

static VALUE
tre_ascan(int argc, VALUE *argv, VALUE self) {
	VALUE pattern, string, char_offset, params, ignore_case, multi_line, num_captures;
	rb_scan_args(argc, argv, "70", &pattern, &string, &char_offset, &params,
			&ignore_case, &multi_line, &num_captures);

	Check_Type(string, T_STRING);

	VALUE rarray = tre_traverse(pattern, string, NUM2LONG(char_offset), params,
			ignore_case, multi_line, NUM2INT(num_captures), Qtrue);

	return rarray;
}

void
Init_tre() {
	mTRE = rb_define_module("TRE");
	rb_define_private_method(mTRE, "__aindex", tre_aindex, -1);
	rb_define_private_method(mTRE, "__ascan",  tre_ascan, -1);
}

