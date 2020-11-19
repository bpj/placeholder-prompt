placeholder-prompt.pl
=====================

    perl placeholder-prompt.pl [-DdEehiKLlOoPpRsvYy] [long options...] <filename>

placeholder-prompt.pl - Interactively fill in placeholders in a text file

DESCRIPTION
-----------

This program loops through all lines of an input file looking for
placeholders (by default of the form `$<WORD>`) prompting you for
a replacement text, optionally showing the previously given value,
if any, as a default answer, and optionally preloading defaults
from a YAML or JSON file and/or saving collected values to a YAML file.

You can override an existing default by prefixing your replacement
value with a "+" at the prompt.

You can abort (leaving any files unchanged) by typing `:a` or
`:q` at the prompt.

OPTIONS
-------

	-d --prompt-default            Prompt for a replacement for known
	                               keys.
	                               (default value: 1)
	-D --no-prompt-default         Do not prompt for a replacement for
	                               known keys.
	-e STR --term-encoding STR     Terminal encoding. (Usually found
	                               automatically, i.e. the actual default
	                               is system dependent.)
	                               (default value: utf-8)
	-h --help                      Show help text.
	-i STR --input-file STR        Path to the input file.
	                               (default value: (undef))
	-K STR --key-regex STR         Perl regular expression to match key
	                               between delimiters in placeholders.
	                               (default value: \w+)
	-l STR -y STR --load-data STR  Path to YAML or JSON file to load
	                               default data from.
	                               (default value: (undef))
	-L STR --left-delimiter STR    Left delimiter for placeholders. NOT a
	                               regular expression!
	                               (default value: $<)
	-o STR --output-file STR       Path to the output file.
	                               (default value: (undef))
	-O --options                   Show options help only.
	-p --prompt-echo               Echo the line containing the
	                               placeholder when prompting.
	                               (default value: 1)
	-P -E --no-prompt-echo         Do not echo the line containing the
	                               placeholder when prompting.
	-R STR --right-delimiter STR   Right delimiter for placeholders.  NOT
	                               a regular expression!
	                               (default value: >)
	-s STR -Y STR --save-data STR  Path to YAML file to save data to.
	                               (default value: (undef))
	-v --version                   Show the program version.


ENCODINGS
---------

Note that while the terminal encoding is queried from the system, and
can be set explicitly with the -e option if the automation fails,
input and output files as well as any data files are assumed to be
UTF-8 encoded. If this is not the case use a tool like iconv, or
(since you must have perl installed anyway to run placeholder-prompt.pl) the Perl
implementation piconv <https://perldoc.pl/piconv> which comes bundled
with perl, to convert your files to UTF-8.

IN PLACE EDITING
----------------

You may specify the same path for input/output file and/or for
load/save data file. If this is the case you will be prompted for
confirmation before overwriting the existing file. However you
will NOT be prompted for confirmation before overwriting an
existing file if the real paths to the source and destination
file are different!

ENVIRONMENT
-----------

You can set your own defaults for some options by defining the
following enviroment variables (defaults shown in parentheses):

    - PH_PROMPT_INPUT_FILE (undef)
    - PH_PROMPT_KEY_REGEX (\w+)
    - PH_PROMPT_LEFT_DELIMITER ($<)
    - PH_PROMPT_LOAD_DATA (undef)
    - PH_PROMPT_OUTPUT_FILE (undef)
    - PH_PROMPT_PROMPT_DEFAULT (1)
    - PH_PROMPT_PROMPT_ECHO (1)
    - PH_PROMPT_RIGHT_DELIMITER (>)
    - PH_PROMPT_SAVE_DATA (undef)
    - PH_PROMPT_TERM_ENCODING (utf-8)
      (The actual default is system dependent!)

DEPENDENCIES
------------

perl >= 5.014

Getopt::Long::Descriptive

IO::Prompt::Tiny

Path::Tiny

Term::Encoding

YAML::PP

See: 

<http://www.cpan.org/modules/INSTALL.html>

<https://www.perl.org/get.html>

LICENSE
-------

This software is Copyright (c) 2020 by Benct Philip Jonsson.

This is free software, licensed under:

  The MIT (X11) License

<http://www.opensource.org/licenses/mit-license.php>

BUGS AND FEATURE REQUESTS
-------------------------

Please report any bugs or feature requests to:

  <bpjonsson+ph-prompt@gmail.com>


