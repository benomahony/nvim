return {
  "SirZenith/oil-vcs-status",
  dependencies = { "stevearc/oil.nvim" },
  opts = function()
    local status_const = require("oil-vcs-status.constant.status")
    local StatusType = status_const.StatusType
    return {
      status_symbol = {
        [StatusType.Added] = "🆕",
        [StatusType.Copied] = "📋",
        [StatusType.Deleted] = "🗑️",
        [StatusType.Ignored] = "🙈",
        [StatusType.Modified] = "✏️",
        [StatusType.Renamed] = "📝",
        [StatusType.TypeChanged] = "🔄",
        [StatusType.Unmodified] = " ",
        [StatusType.Unmerged] = "⚠️",
        [StatusType.External] = "",
        [StatusType.Untracked] = "👻",

        [StatusType.UpstreamAdded] = "🆕",
        [StatusType.UpstreamCopied] = "📋",
        [StatusType.UpstreamDeleted] = "🗑️",
        [StatusType.UpstreamIgnored] = "🙈",
        [StatusType.UpstreamModified] = "✏️",
        [StatusType.UpstreamRenamed] = "📝",
        [StatusType.UpstreamTypeChanged] = "🔄",
        [StatusType.UpstreamUnmodified] = " ",
        [StatusType.UpstreamUnmerged] = "",
        [StatusType.UpstreamUntracked] = "👻",
        [StatusType.UpstreamExternal] = "🔗",
      },
      status_hl_group = {
        [StatusType.Untracked] = false,
        [StatusType.UpstreamUntracked] = false,
      },
    }
  end,
}
