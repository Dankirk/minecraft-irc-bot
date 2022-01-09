alias themesongs.loadfiles {
  unset %themesongs.loaded
  unset %themeline.*.*
  noop $findfile($scriptdir,themesong_*.txt,0,1,themesongs.loadfile $1-)
}
alias -l themesongs.loadfile {

  var %theme = $replace($left($gettok($1-,2-,95),-4),$chr(32),$chr(95))
  if (%theme) {
    var %i = 1
    %max = $lines($1-)
    if (%max > 0) {  
      while (%i <= %max) {
        set %themeline. [ $+ [ %theme ] $+ . $+ [ %i ] ] $read($1-,nt,%i)
        inc %i
      }
      set %themesongs.loaded $addtok(%themesongs.loaded,%theme,32)
    }
  }
}

alias isthemesong {
  if ($0 >= 2 && $istok(%themesongs.loaded,$1,32)) {
    var %id = 1
    var %max = $var(%themeline. [ $+ [ $1 ] $+ ] .*,0)
    var %say = 0

    while (%id < %max) {
      if (%id == 1 && $themesong.nonstrict($($+(%,themeline.,$1,.,%id),2)) == $themesong.nonstrict($2-)) {
        %say = $calc(%id + 1)
      }
      else if (%id > 1 && $themesong.nonstrict($($+(%,themeline.,$1,.,%id),2)) isin $themesong.nonstrict($2-)) {
        %say = $calc(%id + 1)
      }
      inc %id
    }
    if (%say > 0 && %say <= %max) {
      return $($+(%,themeline.,$1,.,%say),2)
    }
  }
  return $null
}

alias themesong.nonstrict {
  var %line = $remove($1-,.,$chr(44),´,',`,?,!)
  %line = $reptok(%line,u,you,0,32) 
  %line = $reptok(%line,wanna,want,0,32) 
  %line = $reptok(%line,them,em,0,32) 
  %line = $remove(%line,all,and)
  %line = $remtok(%line,a,0,32)
  %line = $remtok(%line,an,0,32)
  %line = $replace(%line,you are,youre)
  return %line
}
