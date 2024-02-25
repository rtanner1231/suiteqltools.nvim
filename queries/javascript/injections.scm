((template_string) @sql (#match? @sql "^`[^a-zA-z0-1]*[sS][eE][lL][eE][cC][tT].*") (#offset! @sql 0 1 0 0))

((template_string) @sql (#match? @sql "^`[^a-zA-z0-1]*[wW][iI][tT][hH].*") (#offset! @sql 0 1 0 0))
