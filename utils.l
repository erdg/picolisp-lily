### utils
(de nthcar (N Lst)
   (car (nth Lst N)) )

(de nar (N Lst) (car (nth Lst N)))

(de ndr (N Lst) (nth Lst N))

(de ring-from-list (Lst)
   (macro (circ ^ Lst)) )

(de cl-butlast (Lst)
   (head -1 Lst) )

(de cl-last (Lst)
   (tail 1 Lst) )

(de ring @
   # create a circular list from (evaluated) args
   (apply circ
      (make
         (for "L" (rest)
            (if (atom "L")
               (link "L")
               (chain "L") ) ) ) ) )

(de flat (Lst)
   (fish atom Lst) )

# from "On Lisp"
# (de flatten (X)
#    (recur (X Acc)
#       (cond
#          ((not X) Acc)
#          ((atom X) (cons X Acc))
#          (T (recurse
#                (car X)
#                (recurse (cdr X) Acc) ) ) ) ) )

# from "On Lisp"
(de groupn (Src N)
   (if (=0 N) (err "zero length"))
   # hack to account for off by 1 
   (inc 'N)
   (recur (Src Acc)
      (let Rest (nth Src N)
         (if (pair Rest)
            (recurse Rest (cons (head (- N 1) Src) Acc))
            (flip (cons Src Acc)) ) ) ) )

(de pairlst (Lst)
   (ifn Lst
      NIL
      (cons
         (list (car Lst) (cadr Lst))
         (pairlst (cddr Lst))) ) )

(de symb @
   (any (apply pack (rest))) )


(de leaves% (Tree Test Result)
   (if Tree
      (if (pair Tree)
         (cons
            (tree-leaves%% (car Tree) Test Result)
            (tree-leaves%% (cdr Tree) Test Result) )
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

### macro! - 'macro' with a few more features
#
#  - expressions following the symbol '_' are evaluated and placed (not
#     spliced) in the "expansion"
#
#  - expressions following the symbol '!' are evaluated for side-effects
#     and do NOT appear in the "expansion"
#
(de macro! @Lst
   (macro
      (macro
         ^(_walk @Lst) ) ) )

(de debug-macro! @Lst
   (macro
      '(macro
         ^(_walk @Lst) ) ) )

# : (_walk '(4 _(+ 2 3) 6))
# -> (4 ^ (list (+ 2 3)) 6)
# : (_walk '(4 !(setq X 17) 6))
# -> (4 ^ (prog1 NIL (setq X 17)) 6)
(de _walk (Lst)
   (if Lst
      (if (pair (car Lst))
         (if (atom (cdr @)) # handle quoted atoms
            (cons (car Lst) (_walk (cdr Lst)))
            (cons (_walk (car Lst)) (_walk (cdr Lst))) )
         (cond
            ((= (car Lst) '_)
               (cons
                  '^ (list 'list (cadr Lst))
                  (_walk (cddr Lst)) ) )
            ((= (car Lst) '!)
               (cons
                  '^ (list 'prog1 NIL (cadr Lst))
                  (_walk (cddr Lst)) ) )
            (T (cons (car Lst) (_walk (cdr Lst)))) ) ) ) )

(test '(let Y 2 (* Y Y))
   (let @X 1
      (macro! '(let Y !(inc '@X) @X (* Y Y))) ) )

(test 16
   (let X 1
      (macro!
         (let Y !(setq X 2) _ (* X 2) (* Y Y))) ) )

(de flatten (Lst)
   (fish atom Lst) )
