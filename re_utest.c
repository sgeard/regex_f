#include "tclInterface.h"

#include <string.h>
#include <malloc.h>
#include <stdio.h>
#include <assert.h>

static void testInterface1() {
	int mstart, mend;
	const char* pat = "^<(.+?)>(.+)</(.+?)>$";
	const char* text = "<address>CSG Cambridge</address>";
	int h = -1;
	char* match = (char*) malloc(sizeof(char)*strlen(text));
	int nmatches, i, cf;

	h = tcl_re_compile(pat);

	nmatches = tcl_re_apply(h, text);
	assert(nmatches == 3);
	for (i = 1; i <= nmatches; ++i) {
		tcl_re_get_match_indices(h, i, &mstart, &mend);
		strncpy(match,text+mstart,mend-mstart);
		match[mend-mstart] = '\0';
		if (i == 1 || i == 3) {
			cf = strcmp("address",match);
		} else {
			cf = strcmp("CSG Cambridge",match);
		}
		assert(cf == 0);
	}

	tcl_re_delete(&h);
	printf("testInterface1 ... passed\n");
}

static void testInterface2() {
	const char* pat = "((";
	int h = -1;

	h = tcl_re_compile(pat);
	assert(h == -2);
	printf("testInterface2 ... passed\n");
}

static void testInterface3() {
	const char* pat = "(?:)";
	int h = -1;
	int i;

	for (i=0; i<32; ++i) {
		h = tcl_re_compile(pat);
	}
	assert(h == 31);
	h = tcl_re_compile(pat);
	assert(h == -1);
	printf("testInterface3 ... passed\n");
}

int main(int argc, char** argv) {

	testInterface1();

	testInterface2();

	testInterface3();

	return 0;
}
