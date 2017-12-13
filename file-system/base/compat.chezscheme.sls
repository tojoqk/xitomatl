;; -*- mode: scheme; coding: utf-8 -*-
;; Copyright 2009 Derick Eddington.  My MIT-style license is in the file named
;; LICENSE from the original collection this file is distributed with.
;; Copyright © 2017 Göran Weinholt <goran@weinholt.se>.

(library (xitomatl file-system base compat)
  (export
    directory-enumerator directory-list
    current-directory delete-directory delete-file
    make-directory make-symbolic-link change-mode file-mtime file-ctime
    file-exists? file-regular? file-directory? file-symbolic-link?
    file-readable? file-writable? file-executable? file-size rename-file)
  (import
    (except (rnrs) file-exists?)
    (only (chezscheme) current-directory directory-list file-exists?
          file-regular? file-directory? file-symbolic-link?
          delete-directory)
    (prefix (only (chezscheme) get-mode rename-file) cs:)
    (rename (only (chezscheme) mkdir file-modification-time file-change-time chmod)
            (mkdir make-directory)
            (file-modification-time file-mtime)
            (file-change-time file-ctime)
            (chmod change-mode))
    (only (xitomatl common) format))

  (define-syntax not-implemented
    (syntax-rules ()
      ((_ name ...)
       (begin
         (define (name . args)
           (assertion-violation 'name "not implemented"))
         ...))))

  (not-implemented directory-enumerator make-symbolic-link file-size)

  (define (file-readable? path)
    (fx=? (fxand (cs:get-mode path) #o400) #o400))

  (define (file-writable? path)
    (fx=? (fxand (cs:get-mode path) #o200) #o200))

  (define (file-executable? path)
    (fx=? (fxand (cs:get-mode path) #o100) #o100))

  (define rename-file
    (case-lambda
      ((old new)
       (rename-file old new #f))
      ((old new exists-ok)
       (when (and (not exists-ok) (file-exists? new #f))
         (raise (condition (make-who-condition 'rename-file)
                           (make-message-condition
                            (format "already exists: ~a" new))
                           (make-i/o-filename-error old))))
       (cs:rename-file old new)))))
