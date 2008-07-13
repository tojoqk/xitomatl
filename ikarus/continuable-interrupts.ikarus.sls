(library (xitomatl ikarus continuable-interrupts)
  (export 
    with-continuable-interrupts
    &interrupted-continuable?
    make-&interrupted-continuable
    &interrupted-continuable-continuation
    #|with-continuable-interrupts
    with-continuable-interrupts*
    with-continuable-interrupts/top-level|#)
  (import
    (ikarus))

  
  (begin
    (define &interrupted-continuable-rtd
      (make-record-type-descriptor 
       '&interrupted-continuable
       (record-rtd (make-interrupted-condition))
       #f #f #f 
       '#((immutable continuation))))    
    (define &interrupted-continuable?
      (record-predicate &interrupted-continuable-rtd))      
    (define &interrupted-continuable-cd
      (make-record-constructor-descriptor 
       &interrupted-continuable-rtd
       (make-record-constructor-descriptor (record-rtd (make-interrupted-condition)) #f #f)
       #f))      
    (define make-&interrupted-continuable
      (record-constructor &interrupted-continuable-cd))
    (define &interrupted-continuable-continuation
      (record-accessor &interrupted-continuable-rtd 0)))
  
  #;(define-record-type &interrupted-continuable 
    (parent-rtd 
      (record-rtd (make-interrupted-condition))
      (make-record-constructor-descriptor 
       (record-rtd (make-interrupted-condition)) #f #f))
    (fields 
      continuation))
  
  (define (with-continuable-interrupts thunk)
    (with-exception-handler
      (lambda (ex)
        (if (interrupted-condition? ex)
          (call/cc
            (lambda (cc)
              (raise-continuable (make-&interrupted-continuable cc))))
          (raise-continuable ex)))
      thunk))
  
  (define-syntax with-continuable-interrupts/REPL
    (syntax-rules ()
      [(_ resume-k-name thunk-expr)
       (begin
         (define resume-k-name)
         (catch ex
           ([(&interrupted-continuable? ex)
             (set! resume-k-name (&interrupted-continuable-continuation ex))])
           (thunk-expr)))]))
  
  
  
  #;(begin
  
  (define-syntax with-continuable-interrupts
    ;;; esc is given the continuation of the interrupt handler, 
    ;;; which is the continuation to resume what was interrupted.
    (syntax-rules ()
      [(_ esc thunk)
       (let ([t thunk])
         (unless (procedure? t)
           (assertion-violation 'with-continuable-interrupts "not a procedure" t))
         (parameterize 
             ([interrupt-handler (lambda () (call/cc (lambda (k) (esc k))))])
           (t)))]))

  (define-syntax with-continuable-interrupts*
    ;;; Only works where a (begin ...) with internal defines can work.
    (syntax-rules ()
      [(wci* int-k-name thunk)
       (wci* int-k-name thunk void)]
      [(_ int-k-name thunk indicate-interrupted)
       (begin
         (define int-k-name (void))
         (let ([ii indicate-interrupted]) 
           (unless (procedure? ii)
             (assertion-violation 'with-continuable-interrupts* "not a procedure" ii))
           (call-with-values
            (lambda () 
              (call/cc (lambda (k) 
                         (values (with-continuable-interrupts k thunk)
                                 #t))))
            (case-lambda
              [(int-k) 
               (set! int-k-name int-k)
               (ii)]
              [(thunk-result flag)
               (set! int-k-name (void))
               thunk-result]))))]))
  
  (define-syntax with-continuable-interrupts/top-level
    ;;; Only works where a (begin ...) with internal defines can work.
    (syntax-rules ()
      [(_ int-k-name thunk)
       (with-continuable-interrupts* int-k-name thunk 
                                     (lambda () (display "Back to top-level.\n")))])))
)
