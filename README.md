# picolisp-lily
A PicoLisp frontend for Lilypond.

### What is this?
Lilypond is great, don't get me wrong. But at times it's a little verbose. So I
wrote a bunch of picolisp functions to generate lilypond code.

### How does it work?
It's a naive code generator. Almost every function just prints lilypond code to
the current output channel.  That output is directed to a lilypond file
('.ly'), all expressions are recursively evaluated, and the lilypond file is
sent to the lilypond compiler. Beautiful sheet music PDFs and SVGs result!

### Usage
This library is flexible. It's best for generating short snippets of music -
melodies, chord changes, hits, riffs - anything that you'd like to quickly
share with other musicians at a rehearsal or jam session. Leadsheets are
another great use case. For large scale works or anything that involves a lot
of layout tweaking, it'd probably be best to use lilypond directly.
