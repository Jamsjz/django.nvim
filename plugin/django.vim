" plugin/django.vim
" Vim script loader for django.nvim plugin

if exists('g:loaded_django_nvim')
  finish
endif
let g:loaded_django_nvim = 1

" Forward the setup to the Lua code
function! s:setup(...)
  if a:0 > 0
    lua require('django').setup(vim.fn.eval('a:1'))
  else
    lua require('django').setup()
  endif
endfunction

" Create setup command
command! -nargs=? DjangoSetup call s:setup(<f-args>)

" Create user commands
command! -nargs=0 DjangoFindApp lua require('django.navigation').find_app()
command! -nargs=0 DjangoCommand lua require('django.commands').run_command()
command! -nargs=0 DjangoShell lua require('django.commands').open_shell()
command! -nargs=1 DjangoNewProject lua require('django.commands').new_project(<f-args>)

" Create additional navigation commands
command! -nargs=0 DjangoGoToViews lua require('django.navigation').goto_django_file('views')
command! -nargs=0 DjangoGoToModels lua require('django.navigation').goto_django_file('models')
command! -nargs=0 DjangoGoToUrls lua require('django.navigation').goto_django_file('urls')
command! -nargs=0 DjangoGoToAdmin lua require('django.navigation').goto_django_file('admin')
command! -nargs=0 DjangoGoToTests lua require('django.navigation').goto_django_file('tests')
command! -nargs=0 DjangoGoToForms lua require('django.navigation').goto_django_file('forms')
