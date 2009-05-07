;; Copyright (c) 2009 Derick Eddington.  All rights reserved.  Licensed under an
;; MIT-style license.  My license is in the file named LICENSE from the original
;; collection this file is distributed with.  If this file is redistributed with
;; some other collection, my license must also be included.

; Taken from Oleg's
; http://okmij.org/ftp/Scheme/zipper-in-scheme.txt

#!r6rs
(library (xitomatl zipper base)
  (export
    zipper? zipper-thing zipper-cont
    :zip-keep-val:
    make-zip-iterator
    zip-finish 
    zip-n)
  (import 
    (rnrs)
    (only (xitomatl delimited-control) shift reset)
    (only (xitomatl define) define/? define/?/AV)
    (only (xitomatl predicates) exact-non-negative-integer?))
  
  
  (define-record-type zipper (fields thing cont))
  
  (define :zip-keep-val: (list #T)) ;; unique object
  
  (define/? (make-zip-iterator [iterate procedure?])
    (lambda (x)
      (reset (iterate (lambda (y) (shift sk (make-zipper y sk))) 
                      x))))
  
  (define/? (zip-finish [z zipper?])
    (let loop ([z z])
      (let ([x ((zipper-cont z) (zipper-thing z))])
        (if (zipper? x) (loop x) x))))
  
  (define/?/AV (zip-n [z zipper?] [n exact-non-negative-integer?])
    (do ([i 0 (+ 1 i)]
         [z z ((zipper-cont z) :zip-keep-val:)])
      [(and (= i n)
            (if (zipper? z) #t (AV "not enough elements")))
       z]))
)
