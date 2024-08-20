
(
  (template_string (string_fragment) @injection.content) 
  (#match? @injection.content "^[^a-zA-z0-1]*[sS][eE][lL][eE][cC][tT].*")
  (#set! injection.language "sql")
)

(
  (template_string (string_fragment) @injection.content) 
  (#match? @injection.content "^[^a-zA-z0-1]*[wW][iI][tT][hH].*")
  (#set! injection.language "sql")
)
