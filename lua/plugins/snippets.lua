return {
  "L3MON4D3/LuaSnip",
  build = "make install_jsregexp",
  config = function()
    local ls = require("luasnip")
    local s = ls.snippet
    local t = ls.text_node
    local i = ls.insert_node

    require("luasnip.loaders.from_vscode").lazy_load()

    ls.add_snippets("python", {
      s("paiagent", {
        t({ "from pydantic_ai import Agent", "", "" }),
        t("agent = Agent("),
        t({ "", '    "' }),
        i(1, "openai:gpt-4"),
        t({ '",', "    system_prompt=" }),
        i(2, '"You are a helpful assistant"'),
        t({ ",", ")" }),
        i(0),
      }),
      s("paitool", {
        t("@agent.tool"),
        t({ "", "def " }),
        i(1, "tool_name"),
        t("(ctx: RunContext["),
        i(2, "Deps"),
        t("], "),
        i(3, "arg: str"),
        t({ ") -> str:", '    """' }),
        i(4, "Tool description"),
        t({ '"""', "    " }),
        i(5, "return arg"),
        t({ "", "" }),
        i(0),
      }),
      s("pairun", {
        t("result = "),
        i(1, "agent"),
        t(".run_sync("),
        i(2, '"user prompt"'),
        t(")"),
        t({ "", "print(result.data)" }),
        i(0),
      }),
      s("pairunasync", {
        t("result = await "),
        i(1, "agent"),
        t(".run("),
        i(2, '"user prompt"'),
        t(")"),
        t({ "", "print(result.data)" }),
        i(0),
      }),
      s("paimodel", {
        t({ "from pydantic import BaseModel", "", "" }),
        t("class "),
        i(1, "ResponseModel"),
        t({ "(BaseModel):", "    " }),
        i(2, "field: str"),
        t({ "", "" }),
        i(0),
      }),
      s("paistructured", {
        t({ "from pydantic_ai import Agent", "from pydantic import BaseModel", "", "" }),
        t("class "),
        i(1, "Response"),
        t({ "(BaseModel):", "    " }),
        i(2, "field: str"),
        t({ "", "", "" }),
        t("agent = Agent("),
        t({ "", '    "' }),
        i(3, "openai:gpt-4"),
        t({ '",', "    result_type=" }),
        i(4, "Response"),
        t({ ",", ")" }),
        i(0),
      }),
      s("paideps", {
        t({ "from dataclasses import dataclass", "", "" }),
        t("@dataclass"),
        t({ "", "class " }),
        i(1, "Deps"),
        t({ ":", "    " }),
        i(2, "field: str"),
        t({ "", "" }),
        i(0),
      }),
      s("paisystem", {
        t("@agent.system_prompt"),
        t({ "", "def system_prompt(ctx: RunContext[" }),
        i(1, "Deps"),
        t({ "]) -> str:", "    return f" }),
        i(2, '"You are a helpful assistant"'),
        t({ "", "" }),
        i(0),
      }),
      s("paistream", {
        t("async with "),
        i(1, "agent"),
        t(".run_stream("),
        i(2, '"user prompt"'),
        t({ ") as result:", "    async for message in result.stream():" }),
        t({ "", '        print(message, end="", flush=True)' }),
        t({ "", "" }),
        i(0),
      }),
      s("paivalidator", {
        t("@agent.result_validator"),
        t({ "", "async def validate_result(ctx: RunContext[" }),
        i(1, "Deps"),
        t("], result: "),
        i(2, "str"),
        t({ ") -> str:", "    " }),
        i(3, "return result"),
        t({ "", "" }),
        i(0),
      }),
      s("paifull", {
        t({
          "from pydantic_ai import Agent, RunContext",
          "from pydantic import BaseModel",
          "from dataclasses import dataclass",
          "",
          "",
        }),
        t("@dataclass"),
        t({ "", "class Deps:", "    pass", "", "" }),
        t("class "),
        i(1, "Response"),
        t({ "(BaseModel):", "    " }),
        i(2, "field: str"),
        t({ "", "", "" }),
        t("agent = Agent("),
        t({ "", '    "' }),
        i(3, "openai:gpt-4"),
        t({ '",', "    result_type=" }),
        i(4, "Response"),
        t({ ",", "    deps_type=Deps,", ")" }),
        t({ "", "", "" }),
        t("@agent.tool"),
        t({ "", "def tool(ctx: RunContext[Deps]) -> str:", '    """Tool description"""' }),
        t({ "", "    return " }),
        i(5, '"result"'),
        t({ "", "", "" }),
        i(0),
      }),
    })

    ls.config.set_config({
      history = true,
      updateevents = "TextChanged,TextChangedI",
      enable_autosnippets = true,
    })

    vim.keymap.set({ "i", "s" }, "<C-k>", function()
      if ls.expand_or_jumpable() then
        ls.expand_or_jump()
      end
    end, { silent = true })

    vim.keymap.set({ "i", "s" }, "<C-j>", function()
      if ls.jumpable(-1) then
        ls.jump(-1)
      end
    end, { silent = true })
  end,
}
