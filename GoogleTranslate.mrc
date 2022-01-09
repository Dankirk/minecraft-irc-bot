;Google Translator. Compatible with mIRC 6.32+
;To install just load GoogleTranslator.mrc in the remote section of the scripteditor.
;Credits for the basics go to seroyez. I removed the binvars and used regexes instead, since mirc 6.32.
;Feel free to use this script in any way you like but remember you can flood google with it so use wiseley.
;I'd like to see someone take this script and make some pretty dialog boxes for it and stuff.
;To get a list of all currently available languages use the command !translang in channel.

ON *:INPUT:#: {
  if ($1 == !translate) {
    .ma.googletranslate # $nick $2-
  }
}
alias ma.googletranslate { 
  if ($0 >= 4) {
    var %I = $ticks 
    set -e $+(%,trans.chan.,%I) $1 
    set -e $+(%,trans.nick.,%I) $replace($2,$chr(44),$chr(32))
    set -e $+(%,trans.lang.,%I) $3 $+ $chr(124) $+ EN 
    set -e $+(%,trans.sayit.,%I) 0
    set -e $+(%,trans.phrase.,%I) $remove($4-,$chr(42))
    sockopen $+(remotetrans.,%I) translate.google.com 80  
  }
} 
on *:SOCKOPEN:remotetrans.*: { 
  var %I = $gettok($sockname,2,46)
  sockwrite -n $sockname GET $+(/translate_t?langpair=,$($+(%,trans.lang.,%I),2),&text=,$urlencode($($+(%,trans.phrase.,%I),2))) HTTP/1.0 
  sockwrite -n $sockname Host: translate.google.com 
  sockwrite -n $sockname Connection: Close $+ $crlf $+ $crlf 
} 
on *:SOCKREAD:remotetrans.*: {
  var %I = $gettok($sockname,2,46)

  if ($sockerr) {
    noop $trans.unset(%I)
    return
  }

  sockread 4000 &html
  ; sockread &r
  ; while ($sockbr > 0) {
  ;    bcopy &html %size &r 1 -1
  ;   %size = $calc(%size + $sockbr)
  ;   sockread &r
  ; }

  if ($($+(%,trans.sayit.,%I),2) == 0) {
    if ($getLang($bvar(&html,1-).text)) {

      var %lang = $v1
      if ($len(%lang) == 2 || $len(%lang) == 3) {

        set -e $+(%,trans.sayit.,%I) 2

        if (%lang != en) {

          if (%lang == fi) {
            msg $($+(%,trans.chan.,%I),2) (fi) $($+(%,trans.nick.,%I),2) $+ , vain englantia chatissa, kiitos. Voit puhua yksityisesti kirjoittamalla @PelaajanNimi viestin eteen.
          }
          else if (%lang == de) {
            msg $($+(%,trans.chan.,%I),2) (de) $($+(%,trans.nick.,%I),2) $+ , bitte schreibe englisch im Chat. Um dich mit jemandem privat zu unterhalten, schreibe @Spielername gefolgt von deiner Nachricht.
          }
          else if (%lang == nl) {
            msg $($+(%,trans.chan.,%I),2) (nl) $($+(%,trans.nick.,%I),2) $+ , Alleen engels in de chat. Om een Prive Bericht te sturen naar iemand gebruik je '@spelernaam <bericht>'
          }
          else {

            var %newI = $ticks
            set -e $+(%,trans.chan.,%newI) $($+(%,trans.chan.,%I),2) 
            set -e $+(%,trans.nick.,%newI) $($+(%,trans.nick.,%I),2)
            set -e $+(%,trans.lang.,%newI) en $+ $chr(124) $+ %lang   
            set -e $+(%,trans.sayit.,%newI) 1
            set -e $+(%,trans.phrase.,%newI) Speak English in chat, To chat privately type @PlayerName in front of your messages.

            sockopen $+(remotetrans.,%newI) translate.google.com 80          
          }
        }
        else  {     
          msg $($+(%,trans.chan.,%I),2) $($+(%,trans.nick.,%I),2) seems to speak english already.        
        }
      }
      else {
        echo -s Unidentified language: %lang
      }
      noop $trans.unset(%I)
      return
    }
  }
  else if ($($+(%,trans.sayit.,%I),2) == 1) {
    if ($getTranslation($($+(%,trans.phrase.,%I),2),$bvar(&html,1-).text)) {

      ; Replace , with .
      var %msg = $replace($v1,$chr(44),$chr(46))
      set -e $+(%,trans.sayit.,%I) 2

      ; Fixing "@PlayerName"
      if (!$istok(%msg,$chr(64) $+ PlayerName,32)) {
        var %tok = $findtok(%msg,@,1,32)
        %msg = $deltok(%msg,%tok,32)   
        if ($findtok(%msg,PlayerName,1,32) > 0) {  
          %tok = $v1
        }
        %msg = $puttok(%msg,@PlayerName,%tok,32)
      }

      var %tolang = $gettok($($+(%,trans.lang.,%I),2),2,124)

      msg $($+(%,trans.chan.,%I),2) ( $+ %tolang $+ ) $($+(%,trans.nick.,%I),2) $+ , %msg
      noop $trans.unset(%I)
      return
    }
  }
}
on *:SOCKCLOSE:remotetrans.*: {
  trans.unset $gettok($sockname,2,46)
}
alias -l trans.unset {
  if ($sock(remotetrans. $+ $1)) {
    sockclose remotetrans. $+ $1
  }

  ; No translation was found
  if ($($+(%,trans.sayit.,$1),2) <= 1) {
    msg $($+(%,trans.chan.,$1),2) (??) $($+(%,trans.nick.,$1),2) $+ , Speak English in chat. To chat privately type @PlayerName in front of your messages.
  }

  unset $+(%,trans.chan.,$1) 
  unset $+(%,trans.nick.,$1)
  unset $+(%,trans.lang.,$1)
  unset $+(%,trans.sayit.,$1)
  unset $+(%,trans.phrase.,$1)
}
alias -l getTranslation {
  noop $regex($2, <span title=" $+ $1 $+ " onmouseover="this.style.backgroundColor='#ebeff9'" onmouseout="this.style.backgroundColor='#fff'">(.+?)</span>)
  return $regml(1)
}
alias -l getLang {
  noop $regex($1,<input type=hidden id=nc_dl value="(.+?)">)
  return $regml(1)
}
alias -l urlencode { return $regsubex($1,/(\W)/gS,% $+ $base($asc(\1),10,16,2))) } 
