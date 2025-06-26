return {
  "benomahony/jira.nvim",
  config = function()
    require("jira").setup({
      onepassword_item = "op://employee/vmdzbroprvnfle3yqkxp6hsjti/credential",
    })
  end,
}
