;; Copyright (c) 2009 Derick Eddington.  All rights reserved.  Licensed under an
;; MIT-style license.  My license is in the file named LICENSE from the original
;; collection this file is distributed with.  If this file is redistributed with
;; some other collection, my license must also be included.

#!r6rs
(import
  (rnrs)
  (xitomatl alists)
  (srfi :78 lightweight-testing)
  (only (xitomatl exceptions) catch))

(define-syntax check-AV
  (syntax-rules ()
    [(_ expr)
     (check (catch ex ([else (assertion-violation? ex)])
              expr
              'unexpected-return)
            => #t)]))

(define-syntax check-improper
  (syntax-rules ()
    [(_ who expr)
     (check (catch ex ([else (and (assertion-violation? ex)
                                  (who-condition? ex)
                                  (message-condition? ex)
                                  (list (condition-who ex)
                                        (condition-message ex)))])
              expr
              'unexpected-return)
            => '(who "not a proper alist"))]))

(define-syntax check-not-found
  (syntax-rules ()
    [(_ who key expr)
     (check (catch ex ([else (and (assertion-violation? ex)
                                  (who-condition? ex)
                                  (message-condition? ex)
                                  (irritants-condition? ex)
                                  (positive? (length (condition-irritants ex)))
                                  (list (condition-who ex)
                                        (car (condition-irritants ex))
                                        (condition-message ex)))])
              expr
              'unexpected-return)
            => `(who ,key "key not found"))]))

(define-syntax check-immutable
  (syntax-rules ()
    [(_ who expr)
     (check (catch ex ([else (and (assertion-violation? ex)
                                  (who-condition? ex)
                                  (message-condition? ex)
                                  (list (condition-who ex)
                                        (condition-message ex)))])
              expr
              'unexpected-return)
            => '(who "alist is immutable"))]))


(check-improper assp-ref
  (assp-ref 'oops 'z))
(check-improper assoc-ref
  (assoc-ref '((x . 1) (y . 2) oops) 'z))
(check-improper assq-remove
  (assq-remove "oops" 2))
(check-improper assv-remove
  (assv-remove '((1 . y) oops (3 . z)) 2))
(check-improper assq-update
  (assq-update '((1 . y) oops (3 . z)) 2 (lambda (_) 'bad) 'bad))
(check-improper ass-copy
  (ass-copy '((1 . y) oops (3 . z))))
(check-improper ass-keys
  (ass-keys '((1 . y) oops (3 . z))))
(check-improper ass-entries
  (ass-entries '((1 . y) oops (3 . z))))

;;;; order preserving tests

(check (assoc-replace '((a . 1) (b . 2) (c . 3) (d . 4)) 'b "new") 
       => '((a . 1) (b . "new") (c . 3) (d . 4)))
(check (assv-replace '((a . 1) (b . 2) (c . 3) (d . 4)) 'e "new") 
       => '((a . 1) (b . 2) (c . 3) (d . 4) (e . "new")))
(check (assp-remove '((a . 1) (b . 2) (c . 3) (d . 4)) (lambda (k) (eq? k 'c))) 
       => '((a . 1) (b . 2) (d . 4)))
(check (assq-remove '((a . 1) (b . 2) (c . 3) (d . 4)) 'a) 
       => '((b . 2) (c . 3) (d . 4)))
(check (assoc-update '((a . 1) (b . 2) (c . 3) (d . 4)) 'd number->string 'bad) 
       => '((a . 1) (b . 2) (c . 3) (d . "4")))
(check (assv-update '((a . 1) (b . 2) (c . 3) (d . 4)) 'e string->symbol "new") 
       => '((a . 1) (b . 2) (c . 3) (d . 4) (e . new)))
(check (ass-copy '((a . 1) (b . 2) (c . 3) (d . 4))) 
       => '((a . 1) (b . 2) (c . 3) (d . 4)))
(check (ass-keys '((a . 1) (b . 2) (c . 3) (d . 4))) 
       => '(a b c d))
(check (let-values ([(keys vals)
                     (ass-entries '((a . 1) (b . 2) (c . 3) (d . 4)))])
         (list keys vals)) 
       => '((a b c d) (1 2 3 4)))

;;;; eq-alist tests

(check-AV (make-eq-alist "oops"))
(check-AV (make-eq-alist '(oops)))
(check-AV (make-eq-alist '((k . v)) 'oops))
(define a0 (make-eq-alist))
(check (alist? a0) => #t)
(check (eq-alist? a0) => #t)
(check (alist-mutable? a0) => #t)
(check (alist-equivalence-function a0) => eq?)
(check (alist-size a0) => 0)
(check (alist-ref a0 'x 'default) => 'default)
(check-not-found assq-ref 'x
  (alist-ref a0 'x))
(alist-set! a0 'x 1)
(check (alist-ref a0 'x) => 1)
(check (alist-size a0) => 1)
(alist-set! a0 'y 2)
(check (alist-ref a0 'x) => 1)
(check (alist-ref a0 'y) => 2)
(check (alist-size a0) => 2)
(alist-set! a0 'z 3)
(check (alist-ref a0 'x) => 1)
(check (alist-ref a0 'y) => 2)
(check (alist-ref a0 'z) => 3)
(check (alist-size a0) => 3)
(alist-delete! a0 'x)
(check-not-found assq-ref 'x
  (alist-ref a0 'x))
(check (alist-ref a0 'x 'D) => 'D)
(check (alist-contains? a0 'x) => #f)
(check (alist-contains? a0 'y) => #t)
(check (alist-contains? a0 'z) => #t)
(check (alist-size a0) => 2)
(alist-delete! a0 'y)
(check-not-found assq-ref 'y
  (alist-ref a0 'y))
(check (alist-ref a0 'y 'D) => 'D)
(check (alist-contains? a0 'x) => #f)
(check (alist-contains? a0 'y) => #f)
(check (alist-contains? a0 'z) => #t)
(check (alist-size a0) => 1)
(check-not-found assq-update 'x
  (alist-update! a0 'x (lambda (_) 'bad)))
(alist-update! a0 'x (lambda (x) (symbol->string x)) 'default)
(check (alist-ref a0 'x) => "default")
(check (alist-size a0) => 2)
(alist-update! a0 'z (lambda (x) (- x)) 'default)
(check (alist-ref a0 'z) => -3)
(check (alist-size a0) => 2)
(define a1 (alist-copy a0))
(check (alist-mutable? a1) => #f)
(check (alist-equivalence-function a1) => eq?)
(check-immutable alist-set! 
  (alist-set! a1 'x 42))
(check-immutable alist-delete! 
  (alist-delete! a1 'x))
(check-immutable alist-update! 
  (alist-update! a1 'x values 'D))
(check-immutable alist-clear! 
  (alist-clear! a1))
(let ([k0 (alist-keys a0)]
      [k1 (alist-keys a1)])
  (check k0 => '#(z x))
  (check k1 => k0))
(let-values ([(k0 v0) (alist-entries a0)]
             [(k1 v1) (alist-entries a1)])
  (check k0 => '#(z x))
  (check v0 => '#(-3 "default"))
  (check k1 => k0)
  (check v1 => v0))
(alist-clear! a0)
(check (alist-size a0) => 0)
(check (alist-contains? a0 'x) => #f)
(check (alist-contains? a0 'y) => #f)
(check (alist-contains? a0 'z) => #f)
(check (alist-ref a0 'x 'D) => 'D)
(check (alist-ref a0 'y 'D) => 'D)
(check (alist-ref a0 'z 'D) => 'D)
(check-not-found assq-ref 'x
  (alist-ref a0 'x))
(check-not-found assq-ref 'y
  (alist-ref a0 'y))
(check-not-found assq-ref 'z
  (alist-ref a0 'z))
(check (alist-keys a0) => '#())
(check (let-values ([(k v) (alist-entries a0)]) (cons k v)) => '(#() . #()))
(define a2 (make-eq-alist '((a . #\A) (b . "B") (c . C))))
(check (alist-size a2) => 3)
(check (alist-mutable? a2) => #t)
(let ([k (list 1 2)])
  (alist-set! a2 k 'foo)
  (check (alist-contains? a2 (list 1 2)) => #F)
  (check (alist-ref a2 k) => 'foo)
  (check (alist-ref a2 (list 1 2) 'nope) => 'nope)
  (check-not-found assq-ref (list 1 2)
    (alist-ref a2 (list 1 2)))
  (alist-update! a2 (list 1 2) values 'dflt)
  (check (alist-ref a2 k) => 'foo)
  (alist-delete! a2 (list 1 2))
  (check (alist-contains? a2 k) => #T)
  (alist-delete! a2 k)
  (check (alist-contains? a2 k) => #F))
(define a3 (make-eq-alist '((z . z)) #f))
(check (alist-size a3) => 1)
(check (alist-mutable? a3) => #f)

;;;; eqv-alist tests

(check-AV (make-eqv-alist "oops"))
(check-AV (make-eqv-alist '(oops)))
(check-AV (make-eqv-alist '((k . v)) 'oops))
(define a4 (make-eqv-alist))
(check (alist? a4) => #t)
(check (eqv-alist? a4) => #t)
(check (alist-mutable? a4) => #t)
(check (alist-equivalence-function a4) => eqv?)
(check (alist-size a4) => 0)
(check (alist-ref a4 1 'default) => 'default)
(check-AV (alist-ref a4 1))
(alist-set! a4 1 'x)
(check (alist-ref a4 1) => 'x)
(check (alist-size a4) => 1)
(alist-set! a4 #\2 'y)
(check (alist-ref a4 1) => 'x)
(check (alist-ref a4 #\2) => 'y)
(check (alist-size a4) => 2)
(alist-set! a4 3 'z)
(check (alist-ref a4 1) => 'x)
(check (alist-ref a4 #\2) => 'y)
(check (alist-ref a4 3) => 'z)
(check (alist-size a4) => 3)
(alist-delete! a4 1)
(check-AV (alist-ref a4 1))
(check (alist-ref a4 1 'D) => 'D)
(check (alist-contains? a4 1) => #f)
(check (alist-contains? a4 #\2) => #t)
(check (alist-contains? a4 3) => #t)
(check (alist-size a4) => 2)
(alist-delete! a4 #\2)
(check-AV (alist-ref a4 #\2))
(check (alist-ref a4 #\2 'D) => 'D)
(check (alist-contains? a4 1) => #f)
(check (alist-contains? a4 #\2) => #f)
(check (alist-contains? a4 3) => #t)
(check (alist-size a4) => 1)
(check-AV (alist-update! a4 1 (lambda (_) 'bad)))
(alist-update! a4 1 (lambda (x) (symbol->string x)) 'default)
(check (alist-ref a4 1) => "default")
(check (alist-size a4) => 2)
(alist-update! a4 3 (lambda (x) (symbol->string x)) 'default)
(check (alist-ref a4 3) => "z")
(check (alist-size a4) => 2)
(define a5 (alist-copy a4))
(check (alist-mutable? a5) => #f)
(check (alist-equivalence-function a5) => eqv?)
(check-AV (alist-set! a5 1 42))
(check-AV (alist-delete! a5 1))
(check-AV (alist-update! a5 1 values 'D))
(check-AV (alist-clear! a5))
(let ([k0 (alist-keys a4)]
      [k1 (alist-keys a5)])
  (check k0 => '#(3 1))
  (check k1 => k0))
(let-values ([(k0 v0) (alist-entries a4)]
             [(k1 v1) (alist-entries a5)])
  (check k0 => '#(3 1))
  (check v0 => '#("z" "default"))
  (check k1 => k0)
  (check v1 => v0))
(alist-clear! a4)
(check (alist-size a4) => 0)
(check (alist-contains? a4 1) => #f)
(check (alist-contains? a4 #\2) => #f)
(check (alist-contains? a4 3) => #f)
(check (alist-ref a4 1 'D) => 'D)
(check (alist-ref a4 #\2 'D) => 'D)
(check (alist-ref a4 3 'D) => 'D)
(check-AV (alist-ref a4 1))
(check-AV (alist-ref a4 #\2))
(check-AV (alist-ref a4 3))
(check (alist-keys a4) => '#())
(check (let-values ([(k v) (alist-entries a4)]) (cons k v)) => '(#() . #()))
(define a6 (make-eqv-alist '((1.1 . #\A) (2.2 . "B") (3.3 . C))))
(check (alist-size a6) => 3)
(check (alist-mutable? a6) => #t)
(let ([k (list 1 2)])
  (alist-set! a6 k 'foo)
  (check (alist-contains? a6 (list 1 2)) => #F)
  (check (alist-ref a6 k) => 'foo)
  (check (alist-ref a6 (list 1 2) 'nope) => 'nope)
  (check-AV (alist-ref a6 (list 1 2)))
  (alist-update! a6 (list 1 2) values 'dflt)
  (check (alist-ref a6 k) => 'foo)
  (alist-delete! a6 (list 1 2))
  (check (alist-contains? a6 k) => #T)
  (alist-delete! a6 k)
  (check (alist-contains? a6 k) => #F))
(define a7 (make-eq-alist '((4.4 . z)) #f))
(check (alist-size a7) => 1)
(check (alist-mutable? a7) => #f)

;;;; equal-alist tests

(check-AV (make-equal-alist "oops"))
(check-AV (make-equal-alist '(oops)))
(check-AV (make-equal-alist '((k . v)) 'oops))
(define a8 (make-equal-alist))
(define z (let () (define-record-type Z) (make-Z)))
(check (alist? a8) => #t)
(check (equal-alist? a8) => #t)
(check (alist-mutable? a8) => #t)
(check (alist-equivalence-function a8) => equal?)
(check (alist-size a8) => 0)
(check (alist-ref a8 (list 'x) 'default) => 'default)
(check-AV (alist-ref a8 (list 'x)))
(alist-set! a8 (list 'x) 1)
(check (alist-ref a8 (list 'x)) => 1)
(check (alist-size a8) => 1)
(alist-set! a8 (string #\y) 2)
(check (alist-ref a8 (list 'x)) => 1)
(check (alist-ref a8 (string #\y)) => 2)
(check (alist-size a8) => 2)
(alist-set! a8 z 3)
(check (alist-ref a8 (list 'x)) => 1)
(check (alist-ref a8 (string #\y)) => 2)
(check (alist-ref a8 z) => 3)
(check (alist-size a8) => 3)
(alist-delete! a8 (list 'x))
(check-AV (alist-ref a8 (list 'x)))
(check (alist-ref a8 (list 'x) 'D) => 'D)
(check (alist-contains? a8 (list 'x)) => #f)
(check (alist-contains? a8 (string #\y)) => #t)
(check (alist-contains? a8 z) => #t)
(check (alist-size a8) => 2)
(alist-delete! a8 (string #\y))
(check-AV (alist-ref a8 (string #\y)))
(check (alist-ref a8 (string #\y) 'D) => 'D)
(check (alist-contains? a8 (list 'x)) => #f)
(check (alist-contains? a8 (string #\y)) => #f)
(check (alist-contains? a8 z) => #t)
(check (alist-size a8) => 1)
(check-AV (alist-update! a8 (list 'x) (lambda (_) 'bad)))
(alist-update! a8 (list 'x) (lambda (x) (symbol->string x)) 'default)
(check (alist-ref a8 (list 'x)) => "default")
(check (alist-size a8) => 2)
(alist-update! a8 z (lambda (x) (- x)) 'default)
(check (alist-ref a8 z) => -3)
(check (alist-size a8) => 2)
(define a9 (alist-copy a8))
(check (alist-mutable? a9) => #f)
(check (alist-equivalence-function a9) => equal?)
(check-AV (alist-set! a9 (list 'x) 42))
(check-AV (alist-delete! a9 (list 'x)))
(check-AV (alist-update! a9 (list 'x) values 'D))
(check-AV (alist-clear! a9))
(let ([k0 (alist-keys a8)]
      [k1 (alist-keys a9)])
  (check k0 => `#(,z (x)))
  (check k1 => k0))
(let-values ([(k0 v0) (alist-entries a8)]
             [(k1 v1) (alist-entries a9)])
  (check k0 => `#(,z (x)))
  (check v0 => '#(-3 "default"))
  (check k1 => k0)
  (check v1 => v0))
(alist-clear! a8)
(check (alist-size a8) => 0)
(check (alist-contains? a8 (list 'x)) => #f)
(check (alist-contains? a8 (string #\y)) => #f)
(check (alist-contains? a8 z) => #f)
(check (alist-ref a8 (list 'x) 'D) => 'D)
(check (alist-ref a8 (string #\y) 'D) => 'D)
(check (alist-ref a8 z 'D) => 'D)
(check-AV (alist-ref a8 (list 'x)))
(check-AV (alist-ref a8 (string #\y)))
(check-AV (alist-ref a8 z))
(check (alist-keys a8) => '#())
(check (let-values ([(k v) (alist-entries a8)]) (cons k v)) => '(#() . #()))
(define a10 (make-equal-alist '((a . #\A) (b . "B") (c . C))))
(check (alist-size a10) => 3)
(check (alist-mutable? a10) => #t)
(define a11 (make-equal-alist '((z . z)) #f))
(check (alist-size a11) => 1)
(check (alist-mutable? a11) => #f)

;;;; pred-alist tests

(check-AV (make-pred-alist "oops"))
(check-AV (make-pred-alist '(oops)))
(check-AV (make-pred-alist '((k . v)) 'oops))
(define ap0 (make-pred-alist '((a . #f) (2 . #f) (#\c . #f) ("d" . d))))
(check (alist? ap0) => #t)
(check (pred-alist? ap0) => #t)
(check (alist-mutable? ap0) => #t)
(check (alist-equivalence-function ap0) => 'pred)
(check (alist-size ap0) => 4)
(check (alist-ref ap0 pair? 'default) => 'default)
(check-AV (alist-ref ap0 pair?))
(check-AV (alist-set! ap0 vector? 'bad))
(alist-set! ap0 symbol? 1)
(check (alist-ref ap0 symbol?) => 1)
(check (alist-size ap0) => 4)
(alist-set! ap0 integer? 2)
(check (alist-ref ap0 symbol?) => 1)
(check (alist-ref ap0 integer?) => 2)
(check (alist-size ap0) => 4)
(alist-set! ap0 char? 3)
(check (alist-ref ap0 symbol?) => 1)
(check (alist-ref ap0 integer?) => 2)
(check (alist-ref ap0 char?) => 3)
(check (alist-size ap0) => 4)
(alist-delete! ap0 symbol?)
(check-AV (alist-ref ap0 symbol?))
(check (alist-ref ap0 symbol? 'D) => 'D)
(check (alist-contains? ap0 symbol?) => #f)
(check (alist-contains? ap0 integer?) => #t)
(check (alist-contains? ap0 char?) => #t)
(check (alist-size ap0) => 3)
(alist-delete! ap0 integer?)
(check-AV (alist-ref ap0 integer?))
(check (alist-ref ap0 integer? 'D) => 'D)
(check (alist-contains? ap0 symbol?) => #f)
(check (alist-contains? ap0 integer?) => #f)
(check (alist-contains? ap0 char?) => #t)
(check (alist-size ap0) => 2)
(alist-update! ap0 string? (lambda (x) (list x x)) 'default)
(check (alist-ref ap0 string?) => '(d d))
(check (alist-size ap0) => 2)
(alist-update! ap0 char? (lambda (x) (- x)) 'default)
(check (alist-ref ap0 char?) => -3)
(check (alist-size ap0) => 2)
(define ap1 (alist-copy ap0))
(check (alist-mutable? ap1) => #f)
(check (alist-equivalence-function ap1) => 'pred)
(check-AV (alist-set! ap1 symbol? 42))
(check-AV (alist-delete! ap1 symbol?))
(check-AV (alist-update! ap1 symbol? values))
(check-AV (alist-update! ap1 symbol? values 'D))
(check-AV (alist-clear! ap1))
(let ([k0 (alist-keys ap0)]
      [k1 (alist-keys ap1)])
  (check k0 => '#(#\c "d"))
  (check k1 => k0))
(let-values ([(k0 v0) (alist-entries ap0)]
             [(k1 v1) (alist-entries ap1)])
  (check k0 => '#(#\c "d"))
  (check v0 => '#(-3 (d d)))
  (check k1 => k0)
  (check v1 => v0))
(alist-clear! ap0)
(check (alist-size ap0) => 0)
(check (alist-contains? ap0 symbol?) => #f)
(check (alist-contains? ap0 integer?) => #f)
(check (alist-contains? ap0 char?) => #f)
(check (alist-contains? ap0 string?) => #f)
(check (alist-ref ap0 symbol? 'D) => 'D)
(check (alist-ref ap0 integer? 'D) => 'D)
(check (alist-ref ap0 char? 'D) => 'D)
(check (alist-ref ap0 string? 'D) => 'D)
(check-AV (alist-ref ap0 symbol?))
(check-AV (alist-ref ap0 integer?))
(check-AV (alist-ref ap0 char?))
(check-AV (alist-ref ap0 string?))
(check (alist-keys ap0) => '#())
(check (let-values ([(k v) (alist-entries ap0)]) (cons k v)) => '(#() . #()))
(define ap2 (make-pred-alist '((a . #\A) (b . "B") (c . C))))
(check (alist-size ap2) => 3)
(check (alist-mutable? ap2) => #t)
(define ap3 (make-pred-alist '((z . z)) #f))
(check (alist-size ap3) => 1)
(check (alist-mutable? ap3) => #f)


(check-report)
