{
  programs.nixvim = {

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      deprecation_warnings = false;
      skip_ts_context_commentstring_module = true;
    };

    opts = {
      number = true;
      relativenumber = true;
      mouse = "a";
      showmode = true;
      breakindent = true;
      undofile = true;
      ignorecase = true;
      smartcase = true;
      signcolumn = "yes";
      updatetime = 250;
      timeoutlen = 300;
      splitright = true;
      splitbelow = true;
      list = false;
      listchars = {
        tab = "» ";
        trail = "·";
        nbsp = "␣";
      };
      inccommand = "split";
      cursorline = true;
      scrolloff = 10;
      laststatus = 2;
      cmdheight = 1; # was 0, then 1 at end of options.lua
      autowrite = true;
      conceallevel = 2;
      confirm = true;
      fillchars = {
        foldopen = "";
        foldclose = "";
        fold = " ";
        foldsep = " ";
        diff = "╱";
        eob = " ";
      };
      expandtab = true;
      jumpoptions = "view";
      linebreak = true;
      ruler = false;
      shiftround = true;
      shiftwidth = 2;
      clipboard = "unnamedplus"; # was vim.schedule; direct set is equivalent here
      langremap = true;
    };

    diagnostic.settings = {
      underline = true;
      virtual_text = false;
      update_in_insert = false;
      severity_sort = true;
      signs = false;
    };

    # Conditional display logic + keymap/langmap don't map to opts; keep verbatim.
    extraConfigLuaPre = ''
      if pcall(require, 'vim._core.ui2') then require('vim._core.ui2').enable {} end

      local has_display = vim.env.DISPLAY ~= nil or vim.env.WAYLAND_DISPLAY ~= nil
      local is_tty = vim.env.TERM == 'linux'
      local is_tmux = vim.env.TMUX ~= nil
      if not has_display and (is_tty or is_tmux) then
        vim.o.termguicolors = false
        vim.g.icons_enabled = false
        vim.g.have_nerd_font = false
      else
        vim.o.termguicolors = true
        vim.g.icons_enabled = true
        vim.g.have_nerd_font = true
      end

      vim.cmd [[
        set keymap=russian-jcukenwin
        set iminsert=0
        set imsearch=0
      ]]
      vim.opt.langmap = 'ёй,цw,уe,кr,еt,нy,гu,шi,щo,зp,х[,ъ],'
        .. "фa,ыs,вd,аf,пg,рh,оj,лk,дl,ж\\;,э',"
        .. 'яz,чx,сc,мv,иb,тn,ьm,ё`,'
        .. 'ЙQ,ЦW,УE,КR,ЕT,НY,ГU,ШI,ЩO,ЗP,Х{,Ъ},'
        .. 'ФA,ЫS,ВD,АF,ПG,РH,ОJ,ЛK,ДL,Ж\\:,Э",'
        .. 'ЯZ,ЧX,СC,МV,ИB,ТN,ЬM,Ё~'
      vim.cmd 'let g:netrw_liststyle = 3'
    '';
  };
}
