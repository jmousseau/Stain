


sapply(list.files('./.stain/sources', full.names = TRUE)[!(list.files('./.stain/sources')) %in% '.default_stain_main.R' ], source)
sapply(list.files('./.stain/objects', full.names = TRUE),
                             function(file) { load(file, env = .GlobalEnv) })
main()
