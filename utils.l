### utils
(de untraceAll () (mapc untrace (all)))

(de even? (N) (and (num? N) (=0 (% N 2)) N))
(de odd?  (N) (and (num? N) (n0 (% N 2)) N))

(de nthcar (N Lst)
   (car (nth Lst N)) )

(de nar (N Lst) (car (nth Lst N)))

(de ndr (N Lst) (nth Lst N))

(de ring-from-list (Lst)
   (macro (circ ^ Lst)) )

(de delete-all (Xs Lst Flg)
   (while (++ Xs)
      (setq Lst (delete @ Lst Flg)) ) )

# (de delete-all% (Xs Lst)
#    (filter
#       (list (list 'E)
#          (cons 'nor
#             (make
#                (for X Xs
#                   (link (list '= (cons 'quote X) 'E)))) ) )
#       Lst ) )

(de ring @
   # create a circular list from (evaluated) args
   (apply circ
      (make
         (for "L" (rest)
            (if (atom "L")
               (link "L")
               (chain "L") ) ) ) ) )

### macro! - 'macro' with exciting new features!
#
# - expressions following the symbol '_' are evaluated and placed (not
#   spliced) in the "expansion"
#
# - that's all for now! see experimental ideas below!!
#
(de macro! @Lst
   (macro
      (macro
         ^(_walk @Lst) ) ) )

(de _walk (X)
   (recur (X Acc)
      (ifn X
         (flip Acc)
         (if (pair (car X))
            (if (atom (cdr @))
               (recurse (cdr X) (cons (car X) Acc))
               (recurse (cdr X) (cons (recurse (car X) NIL) Acc)) )
            (case (car X)
               # eval and place result in expansion
               ("_" (recurse (cddr X) (cons (list 'list (cadr X)) '^ Acc)) )
               (T   (recurse (cdr X) (cons (car X) Acc))) ) ) ) ) )
###

### macro!% - more bells and whistles
#
# - expressions following the symbol '!' are evaluated for side-effects
#   and do NOT appear in the "expansion". Good for the lols when debugging
#
(de macro!% @Lst
   (macro
      (macro
         ^(_walk% @Lst) ) ) )

### macro$ - 'use' $-vars in body of macro
#
# $(Var (do-something)) -> 'Var' bound to 'do-something' and
# available in "expansion"
#
(de macro$ @Lst
   (macro
      (use (^($syms @Lst))
         (macro
            ^(_walk% @Lst) ) ) ) )

(de $syms (Lst)
   (if Lst
      (let F (flat Lst)
         (if (= (car F) '$)
            (cons (cadr F) ($syms (cddr F)))
            ($syms (cdr F)) ) ) ) )

# : (_walk '(4 _(+ 2 3) 6))
# -> (4 ^ (list (+ 2 3)) 6)
# : (_walk '(4 !(setq X (+ 2 3)) 6))
# -> (4 ^ (prog1 NIL (setq X (+ 2 3))) 6)
# : (_walk '(4 $(X (+ 2 3)) 6))
# -> (4 ^ (prog1 Nil (setq X (+ 2 3)) 6)
(de _walk% (Lst)
   (if Lst
      (if (pair (car Lst))
         (if (atom (cdr @)) # handle quoted atoms
            (cons (car Lst) (_walk% (cdr Lst)))
            (cons (_walk% (car Lst)) (_walk% (cdr Lst))) )
         (cond
            # eval and place result in expansion
            ((= (car Lst) '_)
               (cons
                  '^ (list 'list (cadr Lst))
                  (_walk% (cddr Lst)) ) )
            # execute side-effects (this is a major fail for debugging)
            ((= (car Lst) '!)
               (cons
                  '^ (list 'prog1 NIL (cadr Lst))
                  (_walk% (cddr Lst)) ) )
            # bind $Vars
            ((= (car Lst) '$)
               (cons
                  '^ (list 'prog1 NIL (list 'setq (caadr Lst) (cadadr Lst)))
                  (_walk% (cddr Lst)) ) )
            (T (cons (car Lst) (_walk% (cdr Lst)))) ) ) ) )
###

### common lisp style macros, oh baby! ;P
(de cl-macro @Lst
   (macro
      (macro
         ^(list
            (deflate (macro (walk-cl-macro ^ @Lst))) ) ) ) )

(de walk-cl-macro X
   (recur (X Acc)
      (ifn X
         (flip Acc)
         (if (pair (car X))
            (if (atom (cdr @))
               (recurse (cdr X) (cons (car X) Acc))
               (recurse (cdr X) (cons (recurse (car X) NIL) Acc)) )
            (case (car X)
               ("`"  (recurse (cdr  X) (cons (lit 'quote) Acc)) )
               (","  (recurse (cddr X) (cons (list 'list (cadr X)) '^ Acc)) )
               (",@" (recurse (cddr X) (cons (cadr X) '^ Acc)) )
               (T    (recurse (cdr  X) (cons (car X) Acc))) ) ) ) ) )
#
### end 'macro' madness


# inspired by Doug Hoyte's 'sharp-backquote' read-macro from "Let Over Lambda"
(de sbq (@Lst)
   (fill
      '((^(at-syms @Lst))
         (fill
            '(^  @Lst) ) ) ) )

# same as above, but no need to quote list
(de \\ Lst
   (let [(@Lst) Lst]
      (fill
         '((^(at-syms @Lst))
            (fill
               '@Lst) ) ) ) )

# @1 ... @N
(de at-syms (Lst)
   (by
      '((X) (stem (chop X) "@"))
      sort
      (filter '((X) (and (pre? "@" (pack X)) (> (length @) 1)))
         (uniq
            (flat Lst) ) ) ) )

(de flat (Lst)
   (fish atom Lst) )

# remove one level of nesting
# (1 2 (3 4 (5 6))) -> (1 2 3 4 (5 6))
(de deflate (Lst)
   (make
      (for L Lst
         (if (pair L)
            (chain @)
            (link L) ) ) ) )

### "On Lisp"
(de mklist (Obj)
   (if (pair Obj) Obj (list Obj)) )

(de flatten (X)
   (recur (X Acc)
      (cond
         ((not  X) Acc)
         ((atom X) (cons X Acc))
         (T (recurse
               (car X)
               (recurse (cdr X) Acc) ) ) ) ) )

(de prune-list (Test Lst)
   (recur (Lst Acc)
      (cond
         ((not Lst) (flip Acc))
         ((pair (car Lst))
            (recurse
               (cdr Lst)
               (cons (recurse (car Lst) NIL) Acc) ) )
         (T (recurse
               (cdr Lst)
               (if (Test (car Lst))
                  Acc
                  (cons (car Lst) Acc) ) ) ) ) ) )

(de groups-of (N Src)
   (if (=0 N) (err "zero length"))
   # hack to account for off by 1
   (inc 'N)
   (recur (Src Acc)
      (let Rest (nth Src N)
         (if (pair Rest)
            (recurse Rest (cons (head (- N 1) Src) Acc))
            (flip (cons Src Acc)) ) ) ) )

(de symb @
   (any (apply pack (rest))) )

(de longer (X Y)
   (and
      (pair X)
      (or
         (not Y)
         (longer (cdr X) (cdr Y)) ) ) )

(de longer@ (X Y)
   (and (longer X Y) X) )

# same as built-in 'maxi'
# no ties, returns first in Lst that wins
(de most (Fn Lst)
   (ifn Lst
      NIL
      (let [Wins (car Lst)  Max (Fn Wins)]
         (for Obj (cdr Lst)
            (let Score (Fn Obj)
               (when (> Score Max)
                  (setq Wins Obj
                        Max  Score) ) ) )
         Wins ) ) )

# returns ties
(de mostn (Fn Lst)
   (ifn Lst
      NIL
      (let [Res (list (car Lst))
            Max (Fn (car Lst)) ]
         (for Obj (cdr Lst)
            (let Score (Fn Obj)
               (cond
                  ((> Score Max)
                     (setq
                        Max Score
                        Res (list Obj) ) )
                  ((= Score Max) (push 'Res Obj) ) )) )
         Res ) ) )

(de best (Fn Lst)
   (ifn Lst
      NIL
      (let Wins (car Lst)
         (for Obj (cdr Lst)
            (if (Fn Obj Wins)
               (setq Wins Obj) ) )
         Wins ) ) )

(de find2 (Fn Lst)
   (if Lst
      (if (Fn (car Lst))
         (cons (car Lst) @)
         (find2 Fn (cdr Lst)) ) ) )

(de before (X Y Lst)
   (let? 1st (car Lst)
      (cond
         ((= Y 1st) NIL)
         ((= X 1st) Lst)
         (T (before X Y (cdr Lst))) ) ) )

(de after (X Y Lst)
   (let? Rest (before Y X Lst)
      (member X Rest) ) )

(de dup? (X Lst)
   (member X (cdr (member X Lst))) )

(de mapcars (Fn . @)
   (use Res
      (for Lst (rest)
         (for L Lst
            (push 'Res (Fn L)) ) )
      (flip Res) ) )

(de every (Fn Lst)
   (if Lst
      (for L Lst
         (NIL (Fn L) NIL)
         T ) ) )

(de some (Fn Lst)
   (if Lst
      (for L Lst
         (T (Fn L) L)
         NIL ) ) )

(de some? (Fn Lst)
   (if Lst
      (for L Lst
         (T (Fn L) T)
         NIL ) ) )

(de explode (Sym)
   (mapcar any (chop (pack Sym))) )

# NOTE - for 'lrec', 'ttrav' and 'trec' "lambda" functions musted be
# preceded by 'lit', e.g. (lit '((X) X)). Common Lisp has "#'", so
# whatever. It's all hidden by macros.

# a function that builds functions that recurse over flat lists
(de lrec (Rec Base)
   (default Base NIL)
   (macro!
      '((Lst)
         (recur (Lst)
            (ifn Lst
               _(if (func? (eval Base)) (list Base) Base)
               (_ Rec
                  (car Lst)
                  '(NIL (recurse (cdr Lst)))) ) ) ) ) )

(de alrec L
   (let (("Rec" Base) L)
      (macro!
         (lrec
            (lit '((It rec) _ "Rec"))
            _ Base ) ) ) )

(de on-cdrs L
   (let ((R B . Ls) L)
      (macro! ((alrec _ R _ B) ^ Ls)) ) )

# a function that builds functions that always traverse the entire tree
(de ttrav (Rec Base)
   (default Base (lit '((X) X)))    # identity fn
   (macro!
      '((Tree)
         (recur (Tree)
            (if (atom Tree)
               _(if (func? (eval Base)) (list Base 'Tree) Base)
               (_ Rec
                  (recurse (car Tree))
                  (if (cdr Tree) (recurse @)) ) ) ) ) ) )

# a function that builds functions that do NOT always traverse the entire tree
(de trec (Rec Base)
   (default Base (lit '((X) X)))
   (macro!
      '((Tree)
         (recur (Tree)
            (if (atom Tree)
               _(if (func? (eval Base)) (list Base 'Tree) Base)
               (_ Rec Tree
                  '(NIL (recurse (car Tree)))
                  '(NIL (if (cdr Tree) (recurse @))) ) ) ) ) ) )

(de atrec L
   (let (("R" B) L)
      (default B 'It)
      (macro!
         (trec
            (lit '((It left right) _ "R"))
            (lit '((It) _ B)) ) ) ) )

# 'It', '(left)' and '(right)' anaphors
(de on-trees L
   (let ((R B . Ls) L)
      (macro!
         ((atrec _ R _ B) ^ Ls) ) ) )

# hack
(de func? (Fn) (or (lamb? Fn) (if (num? Fn) (n1 Fn))) )

# lambda form?
(de lamb? (Fn) (pair (fun? Fn)))

(de n1 (N) (not (=1 N)))



### examples
(de length-lrec (Lst)
   (apply '`(lrec (lit '((X F) (inc (F)))) 0) (lit Lst) ) )

(de length-on-cdrs (Lst)
   (on-cdrs (inc (rec)) 0 Lst) )

(de copy-list-lrec (Lst)
   (apply '`(lrec (lit '((It Rec) (cons It (Rec)))) NIL) ) )

(de some-lrec Lst
   (let ((@Fn . L) Lst)
      (macro
         (apply
            (lrec (lit '((X F) (or (@Fn X) (F)))))
            L ) ) ) )

# lol, wut?
(de find-if-lrec Lst
   (let ((@Fn . L) Lst)  # so no need to quote named functions
      (macro
         (apply
            (lrec (lit '((X F) (if (@Fn X) X (F)))))
            L ) ) ) )


# that's better
(de find-if-on-cdrs (Fn Lst)
   (on-cdrs (if (Fn It) It (rec)) NIL Lst) )

# negate function
(de nfn @Fn
   (macro!
      '(@ (not (apply _(++ @Fn) (rest)))) ) )

# functional intersection
(de fint "Fns"
   (fill
      '(("X")
         (and
            ^(mapcar (sbq '(@1 "X")) "Fns") ) ) ) )

### fand - like fint, but more picolispy
# It - singular argument to function
# @  - result of latest 'and' clause
(de fand "Fns"
   (fill
      '((It)
         (and
            ^(make
               (for "F" "Fns"
                  (if (atom "F")
                     (link ('`(sbq '(@1 It)) "F"))
                     (link "F") ) ) ) ) ) ) )

### end "On Lisp"


### from "Let Over Lambda"

(de leaves% (Tree Test Result)
   (if Tree
      (if (pair Tree)
         (cons
            (leaves% (car Tree) Test Result)
            (leaves% (cdr Tree) Test Result) )
         (if (Test Tree)
            (Result Tree)
            Tree ) ) ) )

(de leaves L
   (let ((@Tree @Test @Result) L)
      (macro
         (leaves%
            @Tree
            '((X) @Test)
            '((X) @Result) ) ) ) )

### end "Let Over Lambda"

# if true, return Obj instead of T
(de =@ @
   (if (apply = (rest))
      (next) ) )


(load "test-utils.l")
(test-utils)
