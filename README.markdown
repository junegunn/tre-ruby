# tre-ruby

tre-ruby is a Ruby binding for TRE library which is "a lightweight, robust, and
efficient POSIX compliant regexp matching library with some exciting features
such as approximate (fuzzy) matching." Since Ruby has builtin regexp support,
this gem will only provide the interface for approximate matching, which is
missing in Ruby.

## Prerequisite

* TRE library (http://laurikari.net/tre/)
  * Download http://laurikari.net/tre/download/

## Installation

```
gem install tre-ruby
```

## Setting up
TRE is an extension module for String. You can extend a String object with it, or include it into String class

```ruby
require 'tre-ruby'

# A string object extended to have approximate matching features
"Clamshell".extend(TRE).ascan /shll/, TRE.fuzziness(2)

# Or you can patch the String class so that every String object can have the extended features.
# (if you think it's appropriate)
class String
  include TRE
end

"Clamshell".ascan /shll/, TRE.fuzziness(2)
```

## Approximate matching
TRE module provides the following instance methods.

### Methods

TRE#axxx methods behave similar to their String#xxx counterparts,
except that you cannot make use of virtual global variables ($&, $`, $', ...)

* aindex
  * Returns the Range (n...m) of the first match
* afind
  * Returns the first matching substring
* ascan
  * Approximate scan. Similar to String#scan.
  * Just like String#scan, TRE#ascan returns Array of Strings or Array of Array of Strings when the given Regexp pattern contains captures.
* ascan_r
  * Same as ascan, but Range instead of String
* asub
  * Substitute the first match.
* agsub
  * Substitute every match.

### TRE::AParams

Every `a-method' of TRE takes a TRE::AParams object as its last parameter.
TRE::AParams controls the approximate matching.

```ruby
params = TRE::AParams.new
params.max_err = 3

str.extend(TRE).ascan /abracadabra/, params
```

There is a shortcut class method TRE.fuzziness(n) which is good enough for most cases. It returns a frozen TRE::AParams object with max_err of n.

```ruby
str.extend(TRE).ascan /abracadabra/, TRE.fuzziness(3)
```

## Examples

### TRE#aindex, TRE#afind
You can locate the pattern (String or Regexp) in the string with aindex and afind.
When the pattern is not found, nil is returned.

```ruby
str = <<-EOF
She sells sea shells by the sea shore.
The shells she sells are surely seashells.
So if she sells shells on the seashore,
I'm sure she sells seashore shells.
EOF

# Returns the first matching range
# - TRE.fuzziness(n) returns frozen TRE::AParams object with max_err of n
str.aindex 'shll', 0, TRE.fuzziness(1)
  # (4...8)

# Returns the first matching substring
str.afind 'shll', 0,  TRE.fuzziness(1)
  # "sell"

# afind from offset 10
str.afind 'shll', 10, TRE.fuzziness(1)
  # "shell"

# Same for Regexp patterns
str.aindex /s[hx]ll/, 0,   TRE.fuzziness(1)
  # (4...8)
```

### TRE#ascan
When the pattern is not found, an empty Array is returned.

```ruby
# Scan
str.ascan /SSELL/i,     TRE.fuzziness(2)
  # [" sell", "shell", "shell", " sell", "shell", " sell", "shell", " sell"]

str.ascan /(SS)(E)LL/i, TRE.fuzziness(2)
  # [[" sell", " s", "e"], ["shell", "sh", "e"], ["shell", "sh", "e"], 
  #  [" sell", " s", "e"], ["shell", "sh", "e"], [" sell", " s", "e"], 
  #  ["shell", "sh", "e"], [" sell", " s", "e"]]

# Scan with block
str.ascan /SSELL/i, TRE.fuzziness(2) do | match_string |
  puts match_string
end

str.ascan /(SS)(E)LL/i, TRE.fuzziness(2) do | first, second |
  puts "#{first} => #{second}"
end
```

### TRE#asub, TRE#agsub

Substitutions.

```ruby
str.asub  'shll', '______', TRE.fuzziness(2)

# Blocks are not supported but you can use back references
str.asub  /(SS)(E)LL/i, "___(\\2 / \\1)__", TRE.fuzziness(2)
str.agsub /(SS)(E)LL/i, "___(\\2 / \\1)__", TRE.fuzziness(2)
```

### Fine-grained control of approximate matching parameters

```ruby
aparams = TRE::AParams.new { |ap|
  ap.cost_ins = 1 
  ap.cost_del = 1
  ap.cost_subst = 2

  ap.max_ins = 10
  ap.max_del = 20
  ap.max_subst = 15
  ap.max_err  = 30
  ap.max_cost = 50
}
str.ascan(/sea shells/, aparams)
```

## Contributing to tre-ruby
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Junegunn Choi. See LICENSE.txt for
further details.

