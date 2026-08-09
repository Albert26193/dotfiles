if vim.g.vscode then
  require('vsc.vs-lazy')
  require('vsc.vs-basic')
  require('vsc.vs-keybinding')
  require('vsc.vs-hop')
  require('vsc.vs-flash')
  require('vsc.vs-comment')
else
  -- Load modules
  require('nv.options')
  require('nv.keymaps')
  require('nv.plugins')
  -- Load configurations after plugins are installed
  require('nv.lsp')
  require('nv.ui')
  -- Load which-key configuration with keybindings
  require('nv.whichkey-config')
end
