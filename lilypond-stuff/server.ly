\version "2.19.37"

#(begin
  (use-modules (ice-9 rdelim) (ice-9 getopt-long) (ice-9 regex))

  (define (lys:start-server port)
    (let ((server-socket (lys:open-socket-for-listening port)))
      (display (format "\nListening on port ~a\n" port))
      (while #t
        (let ((connection (accept server-socket)))
          (lys:fork-worker (lambda () (lys:client-handler (car connection))))))))

  (define (lys:open-socket-for-listening port) (let (
    (s (socket PF_INET SOCK_STREAM 0)))
    (setsockopt s SOL_SOCKET SO_REUSEADDR 1)
    (bind s AF_INET INADDR_ANY port)
    (listen s 5) ; Queue size of 5
    s))

  (define (lys:fork-worker proc) (let* ((child (primitive-fork)))
    (if (zero? child) (begin
      (set! child (primitive-fork))
      (if (zero? child) (proc))
      (primitive-exit)
      ; wait for child to spawn grand-child
      (waitpid child)))))
      
  (define lys:socket #f)
  (define lys:persist #f)

  (define (lys:client-handler socket) (begin
    (set! lys:socket socket)
    ; redirect stdout, stderr to client
    (redirect-port socket (current-output-port))
    (redirect-port socket (current-error-port))
    (display (format "GNU LilyPond Server ~a" (lilypond-version)))
    (while #t (let* ((expr (read-line socket 'trim)))
      (if (not (eof-object? expr)) (lys:eval expr) (break))))))
      
  (define (lys:eval expr)
    (catch #t (lambda () (eval-string expr))
      (lambda (key . params)
        (display (format "Error evaluating expression ~a: ~a\n" key params)))))
  
      
  (define (lys:compile dir . opts)
    (let* ((t1 (get-internal-real-time))
           (opts (lys:translate-compile-options opts))
           (opts (getopt-long opts lys:compile-options-spec))
           (files (car opts))
           (compile-opts (cdr opts)))
      ; change to working directory of client
      (chdir dir)
      (lys:set-compile-options compile-opts)
      (for-each lys:compile-file files)
      (display (format "Elapsed: ~as\n" (lys:elapsed t1 (get-internal-real-time))))
      (if (not (option-ref opts 'persist #f)) (shutdown lys:socket 1))
    ))

  ; add "lyc" to head of opts list, and translate advanced opts e.g. -dbackend
  ; into --dbackend, so getopt-long will be able to deal with them...
  (define (lys:translate-compile-options opts)
    (append (list "lyc") (map (lambda (o) 
      (let* ((display (format "o: ~a\n" o)) (m (string-match "^-d([^=]+)=(.+)" o)))
        (if m (regexp-substitute #f m "--d" 1 "=" 2) o))) opts)))

  (define (lys:set-compile-options opts)
    (for-each (lambda (o)
      (let* ((key (symbol->string (car o)))
             (value (cdr o))
             (fn (eval-string (string-append "lys:opt:" key))))
        (fn value))) 
      opts))
  
  (define (lys:opt:bigpdfs v) (set! ly:bigpdfs (lambda () #t)))
  (define (lys:opt:evaluate v) (eval-string v))
  (define (lys:opt:format v) (lys:add-output-format v))
  (define (lys:opt:pdf v) (lys:add-output-format "pdf"))
  (define (lys:opt:png v) (lys:add-output-format "png"))
  (define (lys:opt:ps v) (lys:add-output-format "ps"))
  (define (lys:opt:output v) (set! (paper-variable #f 'output-filename) v))
  (define (lys:opt:persist v) (set! lys:persist v))
  
  (define lys:output-formats '())
  (define (lys:add-output-format f) (begin
    (if (not (member f lys:output-formats))
      (set! lys:output-formats (append lys:output-formats (list f))))
    (if (eq? (length lys:output-formats) 1)
      (set! ly:output-formats (lambda () lys:output-formats)))))
  
  (define (lys:compile-file fn)
    (if (not (eq? fn '())) (ly:parse-file fn)))

  (define lys:advanced-compile-options '(
    (anti-alias-factor . eval)            (aux-files . eval)
    (backend . string->symbol)            (check-internal-types . eval)
    (clip-systems . eval)                 (delete-intermediate-files . eval)
    (embed-source-code . eval)            (eps-box-padding . eval)
    (gs-load-fonts . eval)                (gs-load-lily-fonts . eval)
    (gui . eval)                          (include-book-title-preview . eval)
    (include-eps-fonts . eval)            (include-settings . eval)
    (job-count . eval)                    (log-file . eval)
    (max-markup-depth . eval)             (midi-extension . identity)
    (music-strings-to-paths . eval)       (paper-size . identity)
    (pixmap-format . string->symbol)      (point-and-click . eval)
    (preview . eval)                      (print-pages . eval)
    (profile-property-accesses . eval)    (protected-scheme-parsing . eval)
    (read-file-list . identity)           (relative-includes . eval)
    (resolution . eval)                   (separate-log-files . eval)
    (show-available-fonts . eval)         (strict-infinity-checking . eval)
    (strip-output-dir . eval)             (strokeadjust . eval)
    (svg-woff . eval)                     (warning-as-error . eval)
  ))
  
  (define lys:advanced-compile-options-spec
    (map (lambda (o) (list (string->symbol (string-append "--d" (symbol->string (car o)))) '(value #t)))
         lys:advanced-compile-options))

  ; define a procedure for each advanced compile option
  (for-each (lambda (o) (let* ((name (string-append "lys:opt:d" (symbol->string (car o))))
                               (translator (eval-string (symbol->string (cdr o))))
                               (display (format "name: ~a\n" (car o)))
                               (display (format "trns: ~a\n" (cdr o)))
                             )
              (module-define! (current-module) name
                (lambda (v) (translator v)))))
            lys:advanced-compile-options)
  
  (define lys:standard-compile-options-spec
    '((bigpdfs        (single-char #\b) (value #f))
                  (evaluate       (single-char #\e) (value #t))
                  (format         (single-char #\f) (value #t))
                  (include        (single-char #\I) (value #t))
                  (loglevel       (single-char #\l) (value #t))
                  (output         (single-char #\o) (value #t))
                  (pdf                              (value #f))
                  (png                              (value #f))
                  (ps                               (value #f))
                  (persist                          (value #f))))

  (define lys:compile-options-spec
    (append lys:standard-compile-options-spec lys:advanced-compile-options-spec))
            
  (define (lys:elapsed t1 t2) (/ (- t2 t1) (* 1.0 internal-time-units-per-second)))
)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#(lys:start-server 12321)
