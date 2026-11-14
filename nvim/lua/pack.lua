local function run_build(name, cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd }):wait()
  if result.code == 0 then
    return
  end

  local output = result.stderr ~= '' and result.stderr or result.stdout
  vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
end

local builds = {
  ['telescope-fzf-native.nvim'] = function(data)
    run_build(data.spec.name, { 'make' }, data.path)
  end,
  LuaSnip = function(data)
    run_build(data.spec.name, { 'make', 'install_jsregexp' }, data.path)
  end,
  ['nvim-treesitter'] = function(data)
    if not data.active then
      vim.cmd.packadd 'nvim-treesitter'
    end
    vim.cmd 'TSUpdate'
  end,
}

vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('pack-build', { clear = true }),
  callback = function(event)
    if event.data.kind == 'delete' then
      return
    end

    local build = builds[event.data.spec.name]
    if not build then
      return
    end

    build(event.data)
  end,
})
