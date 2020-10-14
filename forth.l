(load "pandoric.l")

# The following code is a direct translation of Doug Hoyte's lispy forth
# presented in his book, Let Over Lambda. Adaptions have been made to
# accomodate the differences between PicoLisp and Common Lisp.  A guiding
# principle has been to use 'macro' as much as possible. As such, the resulting
# code is not efficient (nor is it idiomatic picolisp).  That said, I find the
# code to be pretty cool looking and good for a couple of laughs.

# This file defines a simple forth, implemented with the ridiculous functions
# from 'pandoric.l'. The forth image is one big 'job' environment. The forth
# dictionary is implemented as a nested chain of job environments (created via
# 'typ!' -> '*p!'). Somehow it all works.

(de forth ()) # dummy function to access file to e.g. add to the stdlib

(setq forth-registers
   (quote
      pstack
      rstack
      pc
      dict
      compiling
      dtable ) )

(typ! forth-word
   Name
   Prev
   Immediate
   Thread )

(de forth-lookup (Word Last)
   (if Last
      (if (= (Last "getp" 'Name) Word)
         Last
         (forth-lookup Word (Last "getp" 'Prev)) ) ) )

# cons threaded code
(de forth-inner-interpreter ()
   (loop
      (T (and (not pc) (not rstack)) 'ok)
      (cond
         ((fun? (car pc))
            # HACK - stupid picolisp numbers thinking they are functions
            (ifn (atom (car pc))
               ((car pc))
               (push 'pstack (car pc))
               (setq pc (cdr pc)) ) )
         ((pair (car pc))
            (push 'rstack (cdr pc))
            (setq pc (car pc)) )
         ((not pc)
            (setq pc (pop 'rstack)) )
         (T
            (push 'pstack (car pc))
            (setq pc (cdr pc)) ) ) ) )

# NOTE - should implement 'alet' for an exact translation from LOL, but
# 'prog1' will work for now.
(de new-forth ()
   (prog1
      # @ <- create new forth image
      (macro
         (let [^(make (for R forth-registers (link R NIL)))]
            (forth-install-prims)
            (*p! (V) (^ forth-registers)
               (let Word (forth-lookup V dict)
                  (if Word
                     (forth-handle-found)
                     (forth-handle-not-found) ) ) ) ) )
      # install stdlib
      (macro (go-forth @ ^ forth-stdlib)) ) )

(de forth-handle-found ()
   (if (and compiling (not (Word "getp" 'Immediate)))
      (forth-compile-in (Word "getp" 'Thread))
      (prog
         (setq pc (list (Word "getp" 'Thread)))
         (forth-inner-interpreter) ) ) )

(de forth-handle-not-found ()
   (cond
      ((and (pair V) (= (car V) 'quote))
         (if compiling
            (forth-compile-in (cadr V))
            (push 'pstack (cdr V)) ) )
      ((and (pair V) (= (car V) 'postpone))
         (let Word (forth-lookup (cadr V) dict)
            (ifn Word (err "Postpone failed"))
            (forth-compile-in (Word "getp" 'Thread)) ) )
      ((sym? V)
         (err "Word not found") )
      (T
         (if compiling
            (forth-compile-in V)
            (push 'pstack V) ) ) ) )

(de forth-compile-in (@V)
   (macro
      (dict "setp" 'Thread
         (conc (dict "getp" 'Thread) (list '@V))) ) )

# FORTH REPL
#
# : (go-forth F 3 dup * print)
# 9
# -> ok
#
(de go-forth ("Forth" . Words)
   (macro
      (for W '(^(mapcar '`(\\ '@1) Words))
         ("Forth" W) ) ) )


# FORTH PRIMITIVES
(de def-forth-naked-prim @Code
   (macro
      (push 'forth-prim-forms '@Code) ) )

(de def-forth-prim Code
   (macro
      (def-forth-naked-prim
         ^ Code
         (setq pc (cdr pc)) ) ) )

(setq forth-prim-forms NIL)

# (X) lisp fn -> forth primitive
(de forth-unary-word-definer Words
   (macro
      (prog
         ^(mapcar
            '`(\\
               (def-forth-prim @1 NIL
                  (push 'pstack (@1 (pop 'pstack))) ) )
            Words ) ) ) )

# (X Y) lisp fn -> forth primitive
(de forth-binary-word-definer Words
   (macro
      (prog
         ^(mapcar
            '`(\\
               (def-forth-prim @1 NIL
                  (let "Top" (pop 'pstack)
                     (push 'pstack (@1 (pop 'pstack) "Top")) ) ) )
            Words ) ) ) )

(de forth-install-prims ()
   (macro
      (prog
         ^(mapcar
            '`(\\
               (let Thread (lit '(NIL ^(cddr @1)))
                  (setq dict
                     (forth-word
                        (cons 'quote (car '@1))
                        (cons 'quote dict)
                        ^(list (cadr @1))
                        Thread ) ) ) )
            forth-prim-forms ) ) ) )

# definitions
(def-forth-naked-prim branch-if NIL
   (setq pc (if (pop 'pstack)
               (cadr pc)
               (cddr pc) ) ) )

(def-forth-naked-prim compile NIL
   (dict "setp" 'Thread
      (conc
         (dict "getp" 'Thread)
         (list (cadr pc)) ) )
   (setq pc (cddr pc)) )

(def-forth-prim here NIL
   (push 'pstack (tail 1 (dict "getp" 'Thread))) )

(def-forth-prim nop NIL)

(def-forth-prim * NIL
   (push 'pstack (* (pop 'pstack) (pop 'pstack))) )

(def-forth-prim drop NIL
   (pop 'pstack) )

(def-forth-prim dup NIL
   (push 'pstack (car pstack)) )

(def-forth-prim over NIL
   (push 'pstack (cadr pstack)) )

(def-forth-prim swap NIL
   (rot pstack 2) )

(def-forth-prim print NIL
   (println (pop 'pstack)) )

(def-forth-prim >r NIL
   (push 'rstack (pop 'pstack)) )

(def-forth-prim r> NIL
   (push 'pstack (pop 'rstack)) )

###
# NOTE - can't use forth brackets because picolisp "super parens"
(def-forth-prim .| T    # [
   (setq compiling NIL) )

(def-forth-prim |. NIL  # ]
   (setq compiling T) )
###

(def-forth-prim create NIL
   (setq dict (forth-word NIL (cons 'quote dict) NIL NIL)) )

(def-forth-prim name NIL
   (dict "setp" 'Name (pop 'pstack)) )

(def-forth-prim immediate NIL
   (dict "setp" 'Immediate T) )

(def-forth-prim @ NIL
   (push 'pstack (car (pop 'pstack))) )

(def-forth-prim ! NIL
   (let Location (pop 'pstack)
      (set Location (pop 'pstack)) ) )

(forth-unary-word-definer
   not car cdr cadr caddr cadddr )

(forth-binary-word-definer
   = == + - / < > <= >= )

### END FORTH PRIMITIVES

### FORTH STANDARD LIBRARY
(setq forth-stdlib NIL)

(de forth-stdlib-add @All
   (macro
      (setq
         forth-stdlib
         (conc forth-stdlib '@All) ) ) )

(forth-stdlib-add
   create |. dup * .| 'square name )

(forth-stdlib-add
   create |. create |. .| ': name )

(forth-stdlib-add
   : (postpone .|) .| '; name immediate )

(forth-stdlib-add
   : r> drop ; 'exit name )

(forth-stdlib-add
   :
      compile nop
      here swap !
   ; 'then name immediate )

(forth-stdlib-add
   :
      compile 'T
      compile branch-if
      compile nop
      here swap
      compile nop
      here swap !
   ; 'else name immediate )

(forth-stdlib-add
   : compile nop here ; 'begin name immediate )

(forth-stdlib-add
   :
      compile 'T
      compile branch-if
      compile nop
      here !
   ; 'again name immediate )

(forth-stdlib-add
   :
      compile not
      compile branch-if
      compile nop
      here
   ; 'if name immediate )

(forth-stdlib-add
   : over over ; '2dup name )

(forth-stdlib-add
   : swap drop ; 'nip name )

(forth-stdlib-add
   : drop drop ; '2drop name )

(forth-stdlib-add
   : swap over ; 'tuck name )

### END FORTH STANDARD LIBRARY

### FORTH IMAGE INTROSPECTION
(de get-forth-thread ("Forth" Word)
   (let D ("Forth" "getp" 'dict)
      (until (= (D "getp" 'Name) Word)
         (setq D (D "getp" 'Prev)) )
      (D "getp" 'Thread) ) )

(de get-forth-words ("F")
   (let D ("F" "getp" 'dict)
      (make
         (link (D "getp" 'Name))
         (while (setq D(D "getp" 'Prev))
            (link (D "getp" 'Name)) ) ) ) )

### TESTS

(let F (new-forth)
   (go-forth F 1 2 3 + +)
   (test (6) (F "getp" 'pstack))
   (F "setp" 'pstack NIL)
   # (go-forth F 14 'N !)
   # (F "setp" 'pstack NIL)
   # (go-forth F 'N @)
   # (test (14) (F "getp" 'pstack))
   # (F "setp" 'pstack NIL)
   (prinl "LOLFORTH -- PASSED ALL TESTS")
)
