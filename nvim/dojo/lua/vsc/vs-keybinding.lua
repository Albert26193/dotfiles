local ok, util = pcall(require, 'vsc.util')
if not ok or not util.vscode then
  return
end

local vscode = util.vscode
local opts = { noremap = true, silent = true }
local map = vim.keymap.set

local function action(command, action_opts)
  return util.action(command, action_opts)
end

local function map_action(modes, lhs, command, desc)
  map(modes, lhs, action(command), vim.tbl_extend('force', opts, { desc = desc }))
end

local function map_actions(modes, lhs, commands, desc)
  map(modes, lhs, util.run_actions(commands), vim.tbl_extend('force', opts, { desc = desc }))
end

map('n', '<Esc>', function()
  vim.cmd('nohlsearch')
  vscode.action('workbench.action.evenEditorWidths')
end, vim.tbl_extend('force', opts, { desc = 'Clear search highlight and balance groups' }))

map_action('n', '<C-x>', 'whichkey.show', 'Show WhichKey')
map_action('n', '<Space>', 'whichkey.show', 'Show WhichKey')
map_action('v', '<C-x>', 'whichkey.show', 'Show WhichKey')
map_action('v', '<Space>', 'whichkey.show', 'Show WhichKey')

map({ 'n', 'x' }, '<C-b>', '18kzz', vim.tbl_extend('force', opts, { desc = 'Scroll up 18 lines and center' }))
map({ 'n', 'x' }, '<C-d>', '18jzz', vim.tbl_extend('force', opts, { desc = 'Scroll down 18 lines and center' }))
map('n', '<C-n>', '<cmd>nohlsearch<CR>', vim.tbl_extend('force', opts, { desc = 'Clear search highlight' }))

-- Keep wrapped-line movement friendly inside VSCode.
map({ 'n', 'x' }, 'j', 'gj', vim.tbl_extend('force', opts, { desc = 'Move down by display line' }))
map({ 'n', 'x' }, 'k', 'gk', vim.tbl_extend('force', opts, { desc = 'Move up by display line' }))

map_action('n', 'zM', 'editor.foldAll', 'Fold all')
map_action('n', 'zR', 'editor.unfoldAll', 'Unfold all')
map_action('n', 'zc', 'editor.fold', 'Fold')
map_action('n', 'zo', 'editor.unfold', 'Unfold')
map_action('n', 'zj', 'editor.gotoNextFold', 'Go to next fold')
map_action('n', 'zk', 'editor.gotoPreviousFold', 'Go to previous fold')

map_action({ 'n', 'x' }, '<Tab>', 'workbench.action.nextEditorInGroup', 'Next editor in group')
map_action({ 'n', 'x' }, '<S-Tab>', 'workbench.action.previousEditorInGroup', 'Previous editor in group')

map_action({ 'n', 'x' }, '<C-j>', 'workbench.action.navigateDown', 'Focus editor group below')
map_action({ 'n', 'x' }, '<C-k>', 'workbench.action.navigateUp', 'Focus editor group above')
map_action({ 'n', 'x' }, '<C-h>', 'workbench.action.navigateLeft', 'Focus editor group left')
map_action({ 'n', 'x' }, '<C-l>', 'workbench.action.navigateRight', 'Focus editor group right')

map_action({ 'n', 'x' }, '<C-w>j', 'workbench.action.moveEditorToBelowGroup', 'Move editor to below group')
map_action({ 'n', 'x' }, '<C-w>k', 'workbench.action.moveEditorToAboveGroup', 'Move editor to above group')
map_action({ 'n', 'x' }, '<C-w>h', 'workbench.action.moveEditorToLeftGroup', 'Move editor to left group')
map_action({ 'n', 'x' }, '<C-w>l', 'workbench.action.moveEditorToRightGroup', 'Move editor to right group')
map_action('n', '<C-w>J', 'workbench.action.moveEditorToBelowGroup', 'Move editor to below group')
map_action('n', '<C-w>K', 'workbench.action.moveEditorToAboveGroup', 'Move editor to above group')
map_action('n', '<C-w>H', 'workbench.action.moveEditorToLeftGroup', 'Move editor to left group')
map_action('n', '<C-w>L', 'workbench.action.moveEditorToRightGroup', 'Move editor to right group')
map_actions({ 'n', 'x' }, '<C-w>z', {
  'workbench.action.increaseViewSize',
  'workbench.action.increaseViewSize',
  'workbench.action.increaseViewSize',
  'workbench.action.increaseViewSize',
  'workbench.action.increaseViewSize',
  'workbench.action.increaseViewSize',
}, 'Expand current editor group')

map_action('n', 'K', 'editor.action.showHover', 'Show hover')
map_action('n', 'ga', 'references-view.showCallHierarchy', 'Show call hierarchy')
map_action('n', 'gd', 'editor.action.revealDefinition', 'Go to definition')
map_action('n', 'gD', 'editor.action.revealDefinitionAside', 'Go to definition aside')
map_action('n', 'gr', 'references-view.findReferences', 'Find references')
map_action('n', 'ge', 'editor.action.goToReferences', 'Go to references')
map_action('n', 'gh', 'editor.action.goToReferences', 'Go to references')
map_action('n', 'gi', 'editor.action.goToImplementation', 'Go to implementation')

map('n', 'gf', util.find_word_under_cursor, vim.tbl_extend('force', opts, { desc = 'Search word in project' }))
map('n', 'gb', util.find_word_under_cursor, vim.tbl_extend('force', opts, { desc = 'Search word under cursor in files' }))

map_action('n', 'gt', 'workbench.action.closeOtherEditors', 'Close other editors in group')
map_actions('n', 'gT', {
  'workbench.action.focusFirstEditorGroup',
  'workbench.action.closeOtherEditors',
  'workbench.action.focusSecondEditorGroup',
  'workbench.action.closeOtherEditors',
  'workbench.action.focusNextGroup',
  'workbench.action.closeOtherEditors',
  'workbench.action.focusNextGroup',
  'workbench.action.closeOtherEditors',
  'workbench.action.focusSecondEditorGroup',
  'workbench.action.evenEditorWidths',
}, 'Close other editors across groups')

map('v', '<C-c>', '"+y', vim.tbl_extend('force', opts, { desc = 'Copy selection to system clipboard' }))
