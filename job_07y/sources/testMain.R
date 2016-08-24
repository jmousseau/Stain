

main <- function() {
    call_function(hello_world)
}
sapply(list.files('./sources')[!( '../WIP/testMain.R' %in% list.files('./sources'))], source)
sapply(list.files('./.objects'), load)
main()
