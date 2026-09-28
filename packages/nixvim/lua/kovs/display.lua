if pcall(require, 'vim._core.ui2') then
  require('vim._core.ui2').enable {}
end

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
