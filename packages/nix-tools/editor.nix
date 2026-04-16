{lib, ...}: {
  perSystem = {pkgs, ...}: let
    nvim = pkgs.neovim.override {
      extraMakeWrapperArgs = let
        clipPath = pkgs.lib.makeBinPath [pkgs.wl-clipboard pkgs.xclip pkgs.xsel];
      in "--suffix PATH : ${clipPath}";

      configure = {
        packages.myPlugins = with pkgs.vimPlugins; {
          start = [
            nvim-lspconfig
            nvim-cmp
            cmp-nvim-lsp
            cmp_luasnip
            luasnip
          ];
          opt = [];
        };

        # Vimscript config; Lua block inside via heredoc
        customRC = ''
          " completion UI behavior
          set completeopt=menu,menuone,noselect

          " everything below is Lua; note unquoted EOF and nothing after it
          lua << EOF
            -- diagnostics
            vim.diagnostic.config({
              virtual_text = true,
              signs = true,
              underline = true,
              update_in_insert = false,
              severity_sort = true,
            })

            -- nvim-cmp (autocomplete)
            local cmp = require("cmp")
            cmp.setup({
              snippet = {
                expand = function(args) require("luasnip").lsp_expand(args.body) end,
              },
              mapping = cmp.mapping.preset.insert({
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<CR>']      = cmp.mapping.confirm({ select = true }),
                ['<C-n>']     = cmp.mapping.select_next_item(),
                ['<C-p>']     = cmp.mapping.select_prev_item(),
              }),
              sources = {
                { name = 'nvim_lsp' },
                { name = 'luasnip'  },
              },
            })

            -- LSP: nixd with cmp capabilities (using vim.lsp.config, see :help lspconfig-nvim-0.11)
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            vim.lsp.config("nixd", {
              capabilities = capabilities,
            })

            vim.lsp.enable("nixd")

            -- Ensure LSP starts for Nix files
            vim.api.nvim_create_autocmd("FileType", {
              pattern = "nix",
              callback = function(args)
                vim.lsp.start({
                  name = "nixd",
                  cmd = { "nixd" },
                  root_dir = vim.fs.root(args.buf, { "flake.nix", ".git" }),
                  capabilities = capabilities,
                })
              end,
            })

            -- keys
            local map = vim.keymap.set
            map("n", "gd", vim.lsp.buf.definition,   { silent = true })
            map("n", "K",  vim.lsp.buf.hover,        { silent = true })
            map("n", "gr", vim.lsp.buf.references,   { silent = true })
            map("n", "[d", vim.diagnostic.goto_prev, { silent = true })
            map("n", "]d", vim.diagnostic.goto_next, { silent = true })
            map("n", "<leader>rn", vim.lsp.buf.rename, { silent = true })

          ------------------------------------------------------------------
          -- Formatting: manual + toggleable format-on-save
          ------------------------------------------------------------------
          local function format_with_alejandra()
            -- Format current buffer using alejandra via stdin/stdout
            vim.cmd([[%!alejandra --quiet]])
          end

          -- Manual format keybind
          map("n", "<leader>f", format_with_alejandra, { desc = "Format with alejandra" })

          -- Toggleable format-on-save (OFF by default)
          local fmt_group = vim.api.nvim_create_augroup("NixFmt", { clear = true })
          local format_on_save = false

          local function apply_format_autosave(enabled)
            format_on_save = enabled
            vim.api.nvim_clear_autocmds({ group = fmt_group })
            if enabled then
              vim.api.nvim_create_autocmd("BufWritePre", {
                group = fmt_group,
                pattern = "*.nix",
                callback = format_with_alejandra,
              })
              vim.notify("Format on save: ON")
            else
              vim.notify("Format on save: OFF")
            end
          end

          -- Keybind to toggle format-on-save
          map("n", "<leader>tf", function()
            apply_format_autosave(not format_on_save)
          end, { desc = "Toggle format on save" })

          -- Also expose commands for scripts/muscle memory
          vim.api.nvim_create_user_command("Format", function() format_with_alejandra() end, {})
          vim.api.nvim_create_user_command("FormatToggle", function() apply_format_autosave(not format_on_save) end, {})
          vim.api.nvim_create_user_command("FormatEnable", function() apply_format_autosave(true) end, {})
          vim.api.nvim_create_user_command("FormatDisable", function() apply_format_autosave(false) end, {})

          -- Start with format-on-save disabled
          apply_format_autosave(false)

          EOF
        '';
      };
    };
  in {
    packages.nix-nvim = pkgs.symlinkJoin {
      name = "nix-neovim";
      paths = [nvim];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/nvim \
          --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.alejandra
          pkgs.deadnix
          pkgs.statix
          pkgs.nixd
        ]}
      '';

      meta = with lib; {
        description = "Neovim configured for Nix development with LSP, formatting, and linting tools";
        platforms = platforms.all;
        maintainers = [];
        mainProgram = "nvim";
      };
    };
  };
}
