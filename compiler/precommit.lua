vim.b.current_compiler = "precommit"

vim.opt_local.makeprg = "prek --all-files 2>&1"

vim.opt_local.errorformat = table.concat({
  "%f:%l:%c: %m",
  "    %f:%l:%c - %t%.%#: %m",
  "%-G  %f",
  "%-G%.%#Passed",
  "%-G%.%#Failed",
  "%-G%.%#hook id:%.%#",
  "%-G%.%#exit code:%.%#",
  "%-G%.%#error%.%#warning%.%#note%.%#",
  "%-G",
}, ",")
