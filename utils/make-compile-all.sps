#!r6rs
(import
  (rnrs)
  (only (xitomatl file-system base) directory-walk)
  (only (xitomatl file-system paths) path-join)
  (only (xitomatl irregex) irregex-search)
  (only (xitomatl match) match)
  (only (xitomatl predicates) symbol<?)
  (only (xitomatl lists) remove-dups)
  (only (xitomatl common-unstandard) fprintf))

(define libraries-names '())

#;(current-directory "/home/d/zone/scheme/xitomatl")

(directory-walk
 (lambda (path dirs files syms)
   (unless (irregex-search "^\\./(\\.bzr|srfi|gtk|tests|utils|programs)" path)
     (for-each 
      (lambda (f)
        (match (call-with-input-file (path-join path f) read)
          [('library name . _)
           (set! libraries-names (cons name libraries-names))]
          [_ #f]))
      (filter (lambda (f) (irregex-search "\\.sls$" f))
              files))))
 ".")

(set! libraries-names 
      (remove-dups
       (list-sort (lambda (a b)
                    (let loop ([a a] [b b])
                      (cond [(null? a) #t]
                            [(null? b) #f]
                            [(symbol=? (car a) (car b))
                             (loop (cdr a) (cdr b))]
                            [else (symbol<? (car a) (car b))])))
                  (map (lambda (l)
                         ;; remove possible version spec
                         (filter symbol? l))
                       libraries-names))))

#;(for-each (lambda (ln) (write ln) (newline))
          libraries-names)

;; for Ikarus
(call-with-output-file "compile-all.ikarus.sps"
  (lambda (fop)
    (define (pf . a) (apply fprintf fop a))
    (pf ";; Automatically generated by utils/make-compile-all.sps\n")
    (pf ";; Do: ikarus --compile-dependencies compile-all.ikarus.sps\n")
    (pf "(import\n")
    (for-each (lambda (ln)
                (pf "  (only ~s)\n" ln))
              libraries-names)
    (pf ")\n")))

;; for XXX implementation
;; TODO