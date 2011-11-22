;;;; sb-mgraph.asd

(asdf:defsystem #:sb-mgraph
  :serial t
  :depends-on ("mcclim")
  :components ((:file "package")
               (:file "sb-mgraph")))