;; Copyright (c) 2009 Derick Eddington.  All rights reserved.  Licensed under an
;; MIT-style license.  My license is in the file named LICENSE from the original
;; collection this file is distributed with.  If this file is redistributed with
;; some other collection, my license must also be included.

#!r6rs
(import
  (rnrs)
  (xitomatl ports)
  (xitomatl match))

(define top-level-names
  (case-lambda
    [(input)
     (top-level-names input "define" "define-syntax")]
    [(input . look-for)
     (define (match/print look-for)
       (match-lambda
         [('library _ ('export . _) ('import . _) body ...)
          (for-each (match/print look-for) body)]
         [(f (n . r) . b) 
          (and (symbol? f) (memq f look-for) (symbol? n))
          (begin (display n) (newline))]
         [(f n . r) 
          (and (symbol? f) (memq f look-for) (symbol? n))
          (begin (display n) (newline))]
         [_ #f]))
     (let ([look-for (map string->symbol look-for)])
       (for-each (match/print look-for) (call-with-input-file input read-all)))]
    [args
     (assertion-violation (car (command-line)) 
       "invalid command line arguments" args)]))

(apply top-level-names (cdr (command-line)))
