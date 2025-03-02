" Prevent loading multiple times
if exists('g:loaded_djangonvim')
  finish
endif
let g:loaded_djangonvim = 1

" Create plugin commands
command! -nargs=* Django lua require('django').run_django_command(<q-args>)
command! -nargs=0 DjangoRoutes lua require('django').find_routes()
command! -nargs=0 DjangoModels lua require('django').find_models()
command! -nargs=0 DjangoTemplates lua require('django').find_templates()
command! -nargs=0 DjangoApps lua require('django').list_apps()
