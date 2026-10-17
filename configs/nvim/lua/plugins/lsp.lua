return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local default_clangd = vim.lsp.config.clangd

    local on_attach = function(client, bufnr)
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Goto definition" })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover" })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })

      if default_clangd and default_clangd.on_attach then
        default_clangd.on_attach(client, bufnr)
      end
    end

    -- Allow clangd to query cross compilers from compile_commands.json.
    -- Apt: /usr/bin/arm-none-eabi-gcc ; custom: ~/arm-none-eabi/...
    local query_drivers = table.concat({
      "/usr/bin/arm-none-eabi-*",
      vim.fn.expand("~/arm-none-eabi/*"),
    }, ",")

    vim.lsp.config("clangd", {
      on_attach = on_attach,
      cmd = {
        "clangd",
        "--background-index",
        "--compile-commands-dir=build",
        "--query-driver=" .. query_drivers,
      },
      filetypes = { "c", "cpp", "objc", "objcpp" },
    })

    vim.lsp.enable("clangd")
  end,
}
