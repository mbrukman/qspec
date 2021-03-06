\d .tst
fuzzListMaxLength:100

typeNames: `boolean`guid`byte`short`int`long`real`float`char`symbol`timestamp`month`date`datetime`timespan`minute`second`time
typeCodes: 1 2 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19h
typeDefaults:(0b;0Ng;0x0;0h;0;0j;10000e;1000000f;" ";`7;value (string `year$.z.D),".12.31D23:59:59.999999999";2000.01m;2000.01.01;value (string `year$.z.D),".12.31T23:59:59.999";0D0;00:00;00:00:00;00:00:00.000)
typeFuzzN: typeNames!typeDefaults
typeFuzzC: typeCodes!typeDefaults

pickFuzz:{[x;runs]
 $[-11h ~ t:type x;            / [`type] form. Use the default fuzz for the type pneumonic (`symbol/`int/etc)
  runs ? typeFuzzN[x];
  100h ~ type x;               / [{...}] form. function type, x is a fuzz generator
  x each til runs;
  99h ~ type x;                / [`name1`name2...`nameN!...] form. Wants multiple fuzzes
  flip pickFuzz[;runs] each x;
  $[(type x) > 0;              / Any list form. Fuzz should be a fuzzy list of fuzz
   pickListFuzz[x;runs];
   runs ? x                    / Geneal list/atom value form.
   ]]
  } 

pickListFuzz:{[x;runs];
  $[(count x) = 0;                                                / [`type$()] form. Use default fuzz by type, but create variable length lists 
   { y ? typeFuzzC[x]}[abs type x] each runs ? fuzzListMaxLength;
   null[first distinct x] and 1 = count distinct x;               / [`type$n#0N] form. Use default fuzz by type with user specified max list length
   { y ? typeFuzzC[x]}[abs type x] each runs ? count x;           / Type safe comparison needed (symbol list)
   1 = count distinct x;                                          / [`type$n#val] form. Use provided value for fuzz generator with specified max length
   { y ? x }[first x] each runs ? count x;
   runs ? x                                                       / [`type$(val1;val2;val3)] General uniform list form
   ]
 }

runners[`fuzz]:{[expec];
 fuzzResults:fuzzRunCollecter[expec`code] each pickFuzz[expec`vars;expec`runs];
 expec,:exec failedFuzz, fuzzFailureMessages:fuzzFailures from fuzzResults where 0 < count each failedFuzz;
 assertsRun:$[not count fuzzResults;0;max fuzzResults[`assertsRun]];
 $[(expec[`failRate]:(count expec`failedFuzz)%expec`runs) > expec`maxFailRate; 
  expec[`failures`result`assertsRun]:(enlist "Over max failure rate";`fuzzFail;assertsRun);
  expec[`failures`result`assertsRun]:(();`pass;assertsRun)];
 expec
 }

fuzzRunCollecter:{[code;fuzz];
 .tst.assertState:.tst.defaultAssertState;
 code[fuzz];
 $[count .tst.assertState.failures;
   `failedFuzz`fuzzFailures`assertsRun!(fuzz;.tst.assertState.failures;.tst.assertState.assertsRun);
   `failedFuzz`fuzzFailures`assertsRun!(();();.tst.assertState.assertsRun)]
 }
 
