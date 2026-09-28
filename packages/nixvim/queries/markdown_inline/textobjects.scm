; Inline markdown lives in the `markdown_inline` injected tree, not `markdown`.
; A query in queries/markdown/textobjects.scm fails to compile these node types
; ("Invalid node type"), so they go here.
(strong_emphasis) @bold.outer

(emphasis) @italic.outer

(code_span) @code.outer
