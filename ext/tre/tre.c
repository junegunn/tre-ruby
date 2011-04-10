#include "ruby.h"
#include "tre/tre.h"

VALUE mAgrep;
VALUE mTRE;

#define _TRE_APARAM_OVERRIDE(P) \
	VALUE P = rb_funcall(params, rb_intern(#P), 0); \
	if (P != Qnil) aparams->P = NUM2INT(P)
static void
tre_build_aparams(regaparams_t* aparams, VALUE params) {
	// Sets to default
	tre_regaparams_default(aparams);

	// Then override
	_TRE_APARAM_OVERRIDE(cost_ins);
	_TRE_APARAM_OVERRIDE(cost_del);
	_TRE_APARAM_OVERRIDE(cost_subst);
	_TRE_APARAM_OVERRIDE(max_cost);
	_TRE_APARAM_OVERRIDE(max_ins);
	_TRE_APARAM_OVERRIDE(max_del);
	_TRE_APARAM_OVERRIDE(max_subst);
	_TRE_APARAM_OVERRIDE(max_err);
}
#undef _TRE_APARAM_OVERRIDE

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
tre_aindex(int argc, VALUE *argv, VALUE self) {
	VALUE pattern, string, offset, params, ignore_case, multi_line;

	rb_scan_args(argc, argv, "60", &pattern, &string, &offset, &params, &ignore_case, &multi_line);

	Check_Type(string, T_STRING);

	// Compile
	regex_t preg;
	tre_compile_regex(&preg, pattern, ignore_case, multi_line);

	// Build regaparams
	regaparams_t aparams;
	tre_build_aparams(&aparams, params);

	// Find the first match
	regamatch_t match;
	regmatch_t pmatch[1];
	memset(&match, 0, sizeof(match));
	match.nmatch = 1;
	match.pmatch = pmatch;

	long len = RSTRING_LEN(string) - NUM2LONG(offset);
	// TODO: GC?
	VALUE substr = rb_str_substr(string, NUM2LONG(offset), len); 

	int result = tre_reganexec(&preg,
			StringValuePtr(substr),
			len, &match, aparams, 0);
	// Free
	tre_regfree(&preg);

	if (result == REG_NOMATCH)
		return Qnil;
	else
		// Byte offset to char offset
		return rb_str_sublen(string, INT2NUM(NUM2INT(offset) + match.pmatch[0].rm_so) );
}

void
Init_tre() {
	mAgrep = rb_define_module("Agrep");
	mTRE = rb_define_module_under(mAgrep, "TRE");
	rb_define_method(mTRE, "_aindex", tre_aindex, -1);
	// rb_define_method(mTRE, "_amatch", tre_amatch, -1);
}

