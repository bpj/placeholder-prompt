#!/usr/bin/env perl

# This software is Copyright (c) 2020 by Benct Philip Jonsson.
# 
# This is free software, licensed under:
# 
#   The MIT (X11) License
# 
# The MIT License
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to
# whom the Software is furnished to do so, subject to the
# following conditions:
# 
# The above copyright notice and this permission notice shall
# be included in all copies or substantial portions of the
# Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
# WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT
# SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

use 5.014;
use utf8;
use strict;
use warnings;
use warnings FATAL => 'utf8';
use autodie;

use Getopt::Long::Descriptive;
use Term::Encoding qw[term_encoding];
use Encode qw[find_encoding];
use Path::Tiny qw[path];
use IO::Prompt::Tiny qw[prompt];

my $version = '20201118';

sub error;

$0 = path($0)->basename;  

my $term_encoding = term_encoding;

my $enc = get_encoding($term_encoding);

my %default = (
  input_file => 'undef',
  output_file => 'undef',
  load_data => 'undef',
  save_data => 'undef',
  left_delimiter => '$<',
  right_delimiter => '>',
  key_regex => '\w+',
  prompt_default => 1,
  term_encoding => $term_encoding,
);

my %usage_text = (
  pre_text => <<"PRE_TEXT",

$0 - Interactively fill in placeholders in a text file

DESCRIPTION
-----------

This program loops through all lines of an input file looking for
placeholders (by default of the form "\$<WORD>") prompting you for
a replacement text, optionally showing the previously given value,
if any, as a default answer, and optionally preloading defaults
from a YAML or JSON file and/or saving collected values to a YAML file.
You can override an existing default by prefixing your replacement
value with a "+" at the prompt.

OPTIONS
-------
PRE_TEXT

  post_text => <<"POST_TEXT",

ENVIRONMENT
-----------

You can set your own defaults for some options by defining the
following enviroment variables (defaults shown in parentheses):

  - PH_PROMPT_INPUT_FILE ($default{input_file})
  - PH_PROMPT_KEY_REGEX ($default{key_regex})
  - PH_PROMPT_LEFT_DELIMITER ($default{left_delimiter})
  - PH_PROMPT_LOAD_DATA ($default{load_data})
  - PH_PROMPT_OUTPUT_FILE ($default{output_file})
  - PH_PROMPT_PROMPT_DEFAULT ($default{prompt_default})
  - PH_PROMPT_RIGHT_DELIMITER ($default{right_delimiter})
  - PH_PROMPT_SAVE_DATA ($default{save_data})
  - PH_PROMPT_TERM_ENCODING ($default{term_encoding})

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

BUGS AND FEATURE REQUESTS
-------------------------

Please report any bugs or feature requests to:

  <bpjonsson+ph-prompt\@gmail.com>

POST_TEXT

  version_text => <<"VERSION_TEXT",
This is placeholder-prompt.pl version $version
(invoked as $0)

This software is Copyright (c) 2020 by Benct Philip Jonsson.

This is free software, licensed under:

  The MIT (X11) License

VERSION_TEXT

);

for my $key ( keys %default ) {
  $default{$key} = undef_opt($default{$key});
  my $env = $ENV{"\UPH_PROMPT_$key"} // next;
  $default{$key} = $env;
}

my ( $opt, $usage ) = describe_options(
  'perl %c %o <filename>',

  [ 'prompt-default|d',
    "Prompt for a replacement for known keys.",
    opt_default('prompt_default'),
  ],
  [ 'no-prompt-default|D',
    "Don't prompt for a replacement for known keys.",
    +{ implies => +{ prompt_default => 0 }, },
  ],
  [ 'term-encoding|e=s',
    "Terminal encoding. (Usually found automatically.)",
    opt_default('term_encoding'),
  ],
  [ 'help|h' => "Show help text.", +{ shortcircuit => 1 }, ],
  [ 'input-file|i=s',
    "Path to the input file.",
    opt_default('output_file'),
  ],
  [ 'key-regex|K=s',
    "Perl regular expression to match key between delimiters in placeholders.",
    opt_default('key_regex'),
  ],
  [ 'load-data|y|l=s',
    'Name of YAML or JSON file to load default data from.',
    opt_default('load_data'),
  ],
  [ 'left-delimiter|L=s', "Left delimiter for placeholders.",
    opt_default('left_delimiter'),
  ],
  [ 'output-file|o=s', "Path to the output file.",
    opt_default('output_file'),
  ],
  [ 'options|O' => "Show options help only.", +{ shortcircuit => 1 }, ],
  [ 'right-delimiter|R=s', "Right delimiter for placeholders.",
    opt_default('right_delimiter'),
  ],
  [ 'save-data|Y|s=s', "Name of YAML file to save data to.",
    opt_default('save_data'),
  ],
  [ 'version|v', 'Show the program version.',
    +{ shortcircuit => 1 },
  ],
  +{
    show_defaults => 1,
    getopt_conf => [qw(no_ignore_case no_auto_abbrev no_bundling)],
  },
);

if ( $opt->help ) {
  say $usage->leader_text;
  say $usage_text{pre_text};
  say $usage->option_text;
  say $usage_text{post_text};
  exit;
}
elsif ( $opt->options ) {
  say $usage->text;
  exit;
}
elsif ( $opt->version ) {
  print $usage_text{version_text};
  exit;
}

if ( $opt->term_encoding ne $term_encoding ) {
  $enc = get_encoding($opt->term_encoding);
}

my($output_name) = undef_opt($opt->output_file);
my($input_name) = undef_opt($opt->input_file);
($input_name) = @ARGV unless defined $input_name;
$output_name // error 'Output file name required';
$input_name // error 'Input file name required';
my $input = path($input_name)->openr_utf8;
my $output = path($output_name)->openw_utf8;


my $data = +{};

if ( my $fn = undef_opt($opt->load_data) ) {
  my $loaded = ypp()->load_file($fn);
  unless ( 'HASH' eq ref $loaded ) {
    error "Expected YAML/JSON file to contain a mapping/object: $fn";
  }
  $data = $loaded;
}

my $regex = do {
  my $left = quotemeta $enc->decode($opt->left_delimiter);
  my $right = quotemeta $enc->decode($opt->right_delimiter);
  my $key = $enc->decode($opt->key_regex);
  qr/$left($key)$right/;
};

my $prompt_default = $enc->decode($opt->prompt_default);

while (<$input>) {
  my $line = my $text = $_;
  $text =~ s{$regex}{
    prompt_replace($line, $1, $data, $prompt_default);
  }ge;
  print $output $text;
}

close $input;
close $output;

if ( my $fn = undef_opt($opt->save_data) ) {
  ypp()->dump_file($fn, $data);
}

sub error {
  my $msg = shift;
  $msg = sprintf $msg, @_ if @_;
  die $enc->encode($msg . "\n");
}

sub get_encoding {
  my($name) = @_;
  return find_encoding($name) // die "Unknown encoding: $name";
}

sub opt_default {
  return +{ default => $default{$_[0]} };
}

sub undef_opt {
  my($val) = @_;
  $val // return;
  return if 'undef' eq $val;
  return $val;
}

sub ypp {
  state $ypp = do {
    require YAML::PP;
    YAML::PP->new( schema => ['JSON'] );
  };
  return $ypp;
}

sub prompt_replace {
  my($line, $key, $data, $prompt_default) = @_;
  my $val = $data->{$key};
  if ( $prompt_default or !defined($val) ) {
    my $prompt_key = $enc->encode("$key:");
    my $prompt_default = defined($val) ? $enc->encode($val) : undef;
    print $enc->encode($line);
    my $answer = prompt $prompt_key, $prompt_default;
    if ( defined $answer ) {
      $answer = $enc->decode($answer);
      if ( $answer =~ s{^\+}{} ) {
        $val = $data->{$key} = $answer;
      }
      else {
        $val = $answer;
        $data->{$key} //= $answer;
      }
    }
  }
  return $val;
}

