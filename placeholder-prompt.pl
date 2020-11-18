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

my $version = '202011182230';

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
  prompt_echo => 1,
  term_encoding => $term_encoding,
);

my %usage_text = (
  pre_text => <<"PRE_TEXT",

$0 - Interactively fill in placeholders in a text file

DESCRIPTION
-----------

This program loops through all lines of an input file looking for
placeholders (by default of the form `\$<WORD>`) prompting you for
a replacement text, optionally showing the previously given value,
if any, as a default answer, and optionally preloading defaults
from a YAML or JSON file and/or saving collected values to a YAML file.

You can override an existing default by prefixing your replacement
value with a "+" at the prompt.

You can abort (leaving any files unchanged) by typing `:a` or
`:q` at the prompt.

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
    - PH_PROMPT_PROMPT_ECHO ($default{prompt_echo})
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
    "Do not prompt for a replacement for known keys.",
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
  [ 'prompt-echo|p',
    "Echo the line containing the placeholder when prompting.",
    opt_default('prompt_echo'),
  ],
  [ 'no-prompt-echo|E|P',
    "Do not echo the line containing the placeholder when prompting.",
    +{ implies => +{ prompt_echo => 0 } },
  ],
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
  say q{ } x 4, $usage->leader_text;
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
my $prompt_echo = $enc->decode($opt->prompt_echo);

my @lines = path($input_name)->lines_utf8;

for my $line ( @lines ) {
  my $text = $line;
  $line =~ s{$regex}{
    prompt_replace($text, $1, $data, $prompt_default,$prompt_echo);
  }ge;
}

if ($input_name eq $output_name) {
  my $name = $enc->decode($output_name);
  my $write = prompt_yn("Really overwrite $name?", 0);
  if ( $write ) {
    say $enc->encode("Overwriting $name");
    path($output_name)->spew_utf8(\@lines);
  }
  else {
    say $enc->encode("Discarding changes");
  }
}
else {
  path($output_name)->spew_utf8(\@lines);
}

if ( my $fn = undef_opt($opt->save_data) ) {
  if ( ($opt->load_data // "") eq $fn ) {
    my $name = $enc->decode($fn);
    my $write = prompt_yn("Really overwrite data in $name?", 0);
    if ( $write ) {
      say $enc->encode("Overwriting data in $name");
      ypp()->dump_file($fn, $data);
    }
    else {
      say $enc->encode("Discarding data changes");
    }
  }
  else {
    ypp()->dump_file($fn, $data);
  }
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

sub prompt_yn {
  state $yes_or_no = '(y[es]/n[o])';
  state $yes = $enc->encode('y');
  state $no = $enc->encode('n');
  my($prompt, $default) = @_;
  $prompt = $enc->encode("$prompt $yes_or_no");
  $default = $default ? $yes : $no;
  my $answer = "";
  while ($answer !~ m{^(?:y(?:es)?|no?)$}i ) {
    $answer = prompt $prompt, $default;
    $answer //= "";
    $answer = $enc->decode($answer);
  }
  return $answer =~ m{^y}i;
}

sub prompt_replace {
  my($line, $key, $data, $prompt_default, $prompt_echo) = @_;
  my $val = $data->{$key};
  if ( $prompt_default or !defined($val) ) {
    my $prompt_key = $enc->encode("$key:");
    my $prompt_default = defined($val) ? $enc->encode($val) : undef;
    print $enc->encode($line) if $prompt_echo;
    my $answer;
    until ( defined $answer ) {
      $answer = prompt $prompt_key, $prompt_default;
      $answer = $enc->decode($answer);
      if ( $answer =~ m{^\:[aq]$}) {
        exit if prompt_yn('Really abort?', 0);
        $answer = undef;
      }
      elsif ( $answer =~ s{^\+}{} ) {
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

