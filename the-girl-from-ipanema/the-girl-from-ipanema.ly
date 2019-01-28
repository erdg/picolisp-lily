\version "2.19.82"
\layout
{
indent = 0
\context
{
\Score
\omit BarNumber
}
}
\header
{
tagline = ##f
title = "The Girl from Ipanema"
composer = "Jobim"
}
#(set-global-staff-size 32)
\include "lilyjazz.ily"
\include "jazzchords.ly"
\score
{
<<
\chords
{ 
\set chordChanges = ##t
\set minorChordModifier = \markup { - }
\repeat volta 2
{
f1:maj7
f1:maj7
g1:7
g1:7
g1:min7
ges1:7
}
\alternative 
{
{
f1:maj7
ges1:7
}
{
f1:maj7
f1:maj7
}
}
ges1:maj7
ges1:maj7
b1:7
b1:7
fis1:min7
fis1:min7
d1:7
d1:7
g1:min7
g1:min7
ees1:7
ees1:7
a1:min7
d1:7.5+
g1:min7
c1:7.5+
f1:maj7
f1:maj7
g1:7
g1:7
g1:min7
ges1:7
f1:maj7
f1:maj7
}
\new Staff
{
\relative c''
{
\clef treble
\numericTimeSignature
\time 4/4
\repeat volta 2
{
g4.
e8
e8
d4
g8~
g4
e8
e8~
e8
e8
d8
g8~
g4
e4
e4
d8
g8~
g8
g8
e8
e8~
e8
e8
d8
f8~
\override Staff.Clef.stencil = ##f
\break
f8
d4
d8~
d8
d8
c8
e8~
e8
c4
c8~
c8
c8
bes4
}
\alternative 
{
{
r4
c2.~
c1
}
{
r4
c2.~
c2.
r4
\bar "||" 
\break
}
}
{
f1~
\tuplet 3/2
{
f4
ges4
f4
}
\tuplet 3/2
{
ees4
f4
ees4
}
des4.
ees8~
ees2~
ees2.
r8
gis8~
\break
gis1~
\tuplet 3/2
{
gis4
a4
gis4
}
\tuplet 3/2
{
fis4
gis4
fis4
}
e4.
fis8~
fis2~
fis2.
r8
a8~
\break
a1~
\tuplet 3/2
{
a4
bes4
a4
}
\tuplet 3/2
{
g4
a4
g4
}
f4.
g8~
g2~
g2
\tuplet 3/2
{
r4 a4 bes4
}
\break
\tuplet 3/2
{
c4
c,4
d4
}
\tuplet 3/2
{
e4
f4
g4
}
gis2.
a4
\tuplet 3/2
{
bes4
bes,4
c4
}
\tuplet 3/2
{
d4
e4
f4
}
fis1
\bar "||" 
\break
g4.
e8
e8
d4
g8~
g4
e8
e8~
e8
e8
d8
g8~
g4
e4
e4
d8
g8~
g8
g8
e8
e8~
e8
e8
d8
a'8~
\break
a4.
f8
f8
f8
d8
c'8~
c4.
e,8
\tuplet 3/2
{
e4
e4
d4
}
e1~
e4
r4
r2
\bar "|." 
}
}
}
>>
}
