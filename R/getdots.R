## NOTE: this has problems when '...' contains quoted names that have special symbols
## for a better option see the logic in setkey

getdots <- function()
{
  # return a string vector of the arguments in '...'
  # My long winded way: gsub(" ","",unlist(strsplit(deparse(substitute(list(...))),"[(,)]")))[-1]
  # Peter Dalgaard's & Brian Ripley helped out and ended up with :
  as.character(match.call(sys.function(-1L), call=sys.call(-1L), expand.dots=FALSE)$...)
}
