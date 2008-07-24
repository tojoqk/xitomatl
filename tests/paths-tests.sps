#!r6rs
(import
  (rnrs)
  (xitomatl file-system paths)
  (xitomatl srfi lightweight-testing))

(check (absolute-path? "")
       => #f)
(check (absolute-path? "a")
       => #f)
(check (absolute-path? " a ")
       => #f)
(check (absolute-path? "a/ b")
       => #f)
(check (absolute-path? "a// //b")
       => #f)
(check (absolute-path? "a////b///")
       => #f)
(check (absolute-path? "/")
       => #t)
(check (absolute-path? "///// //")
       => #t)
(check (absolute-path? "/a")
       => #t)
(check (absolute-path? "/a/b")
       => #t)
(check (absolute-path? "//a/b")
       => #t)
(check (absolute-path? "/////a //b//")
       => #t)

(check (relative-path? "")
       => #f)
(check (relative-path? " ")
       => #t)
(check (relative-path? " a ")
       => #t)
(check (relative-path? "a/b")
       => #t)
(check (relative-path? "a// // b ")
       => #t)
(check (relative-path? "a////b///")
       => #t)
(check (relative-path? "/")
       => #f)
(check (relative-path? "///// //")
       => #f)
(check (relative-path? "/a")
       => #f)
(check (relative-path? "/a/b")
       => #f)
(check (relative-path? "//a/b")
       => #f)
(check (relative-path? "/////a //b//")
       => #f)

(check (path-join)
       => "")
(check (path-join "a")
       => "a")
(check (path-join "/")
       => "/")
(check (path-join "/" "a")
       => "/a")
(check (path-join "/a")
       => "/a")
(check (path-join " " "a")
       => " /a")
(check (path-join "" "a")
       => "a")
(check (path-join "" "/a")
       => "a")
(check (path-join "a" "b")
       => "a/b")
(check (path-join "a" "" "b" "")
       => "a/b")
(check (path-join "" "a" "b")
       => "a/b")
(check (path-join "a/b")
       => "a/b")
(check (path-join "/a/b")
       => "/a/b")
(check (path-join "" "/a/b")
       => "a/b")
(check (path-join "//a///b")
       => "/a/b")
(check (path-join "a " " b")
       => "a / b")
(check (path-join "/a" "b")
       => "/a/b")
(check (path-join "/" "a" "b")
       => "/a/b")
(check (path-join "/" "a/b")
       => "/a/b")
(check (path-join "/////a/////" "b" "c")
       => "/a/b/c")
(check (path-join "" "/////a/////" "b" "c")
       => "a/b/c")
(check (path-join "/////a/////" "/b/" "c////")
       => "/a/b/c")
(check (path-join "" "/////a/////" "///b" "///c")
       => "a/b/c")
(check (path-join "a" "b" "c" "d" "e" "f")
       => "a/b/c/d/e/f")
(check (path-join "a" "b/c/d" "e/f")
       => "a/b/c/d/e/f")
(check (path-join "a" "/b//c///d" "e//////f")
       => "a/b/c/d/e/f")
(check (path-join "/a" "b" "c" "d" "e" "f")
       => "/a/b/c/d/e/f")
(check (path-join "//////" "a" "b" "c" "d" "e" "f")
       => "/a/b/c/d/e/f")
(check (path-join "//////" "//////a" "b////////" "c/" "/d//" "//e" "f////////////////")
       => "/a/b/c/d/e/f")
(check (path-join "/// ///" "//////a" "b b////////" "c/" "/d//" "//e" "f////////////////  ")
       => "/ /a/b b/c/d/e/f/  ")

(check (path-split "")
       => '())
(check (path-split "/")
       => '("/"))
(check (path-split "a")
       => '("a"))
(check (path-split "ab cd")
       => '("ab cd"))
(check (path-split "a/b")
       => '("a" "b"))
(check (path-split "aa a/b bb bbb")
       => '("aa a" "b bb bbb"))
(check (path-split "/a/b")
       => '("/" "a" "b"))
(check (path-split " /a/b")
       => '(" " "a" "b"))
(check (path-split " /a / b")
       => '(" " "a " " b"))
(check (path-split "//// a / b bbbbb ")
       => '("/" " a " " b bbbbb "))

(check (cleanse-path "")
       => "")
(check (cleanse-path "/")
       => "/")
(check (cleanse-path "//")
       => "/")
(check (cleanse-path "////////////")
       => "/")
(check (cleanse-path "a")
       => "a")
(check (cleanse-path "ab cd")
       => "ab cd")
(check (cleanse-path "a/b")
       => "a/b")
(check (cleanse-path "a//b")
       => "a/b")
(check (cleanse-path "a/b/")
       => "a/b")
(check (cleanse-path "a/////////////b")
       => "a/b")
(check (cleanse-path "a////b//////")
       => "a/b")
(check (cleanse-path "aa a/b bb bbb")
       => "aa a/b bb bbb")
(check (cleanse-path "/a/b")
       => "/a/b")
(check (cleanse-path " /a/b")
       => " /a/b")
(check (cleanse-path "//a")
       => "/a")
(check (cleanse-path "//////a//////")
       => "/a")
(check (cleanse-path "//////a////bb//ccc///////dddd/eeeee//")
       => "/a/bb/ccc/dddd/eeeee")

(check (path=? "/" "//" "///") 
       => #t)
(check (path=? "/a" "////a" "//a/") 
       => #t)
(check (path=? "//////a////bb//ccc///////dddd/eeeee//"
               "/a/bb/ccc/dddd/eeeee"
               "///a/bb///ccc///dddd//eeeee") 
       => #t)
(check (path=? "a/bb/ccc/" "a//bb///ccc") 
       => #t)
(check (path=? "a/bb/ccc/" "a//bb///ccc" "a///bb//ccc" "a//bb///ccc/" "a//bb///ccc//" 
               "a//bb///ccc" "a//bb///ccc" "a/bb/ccc" "a//bb//ccc" "a/bb/ccc/") 
       => #t)


(check-report)
