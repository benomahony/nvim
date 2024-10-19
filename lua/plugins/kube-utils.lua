return {
  {
    "h4ckm1n-dev/kube-utils-nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "folke/which-key.nvim" },
    lazy = true,
    event = "VeryLazy",
    config = true,
    cmd = { "OpenK9s", "OpenK9sSplit", "KubectlApplyFromBuffer", "ViewPodLogs" },
    keys = {
      { "<leader>k", group = "k8s", desc = "󱃾 k8s" },
      { "<leader>kA", "<cmd>KubectlApplyFromBuffer<CR>", desc = "Kubectl Apply From Buffer" },
      { "<leader>kK", "<cmd>OpenK9sSplit<CR>", desc = "Split View K9s" },
      { "<leader>kk", "<cmd>OpenK9s<CR>", desc = "Open K9s" },
      { "<leader>kf", "<cmd>JsonFormatLogs<CR>", desc = "Format JSON" },
      { "<leader>kv", "<cmd>ViewPodLogs<CR>", desc = "View Pod Logs" },
    },
  },
}
