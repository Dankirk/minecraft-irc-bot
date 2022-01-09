alias icanhasgrief {

  .timerICHG off
  unset %ICHG.*

  set %ICHG.scanningF 0 
  set %ICHG.keywords +ign+ +in+game+name+
  set %ICHG.scanningK 1
  set %ICHG.pagesToScan $iif($readini(MA.ini,n,GrieferForumScan,pagesToSearch) > 0,$v1,1)
  set %ICHG.scanningD 1

  set %ICHG.domains $readini(MA.ini,n,GrieferForumScan,domains)

  echo -s $timestamp ICHG: scan initiated with $numtok(%ICHG.domains,32) domains, $numtok(%ICHG.keywords,32) keywords, %ICHG.pagesToScan search result pages

  set %ICHG.filter unbanning apparently appearing currently account accounts characters character minecraft offline protected assistance technique yesterday recruitment
  set %ICHG.nextpageText <!-- end: multipage_page_current --><!-- start: multipage_page -->
  ICHG.Login

}
alias ichg.addnew {
  if ($1 && %ma.DB) {
    var %sql = INSERT into Blacklist ( Name ) VALUES ( $mysql_qt($mysql_real_escape_string(%ma.DB,$1)) )
    if ($mysql_exec(%ma.DB, %sql)) {
      echo -a Added: $1
    }
    else {
      echo -a Error adding: $1
    }
  }
}
alias ICHG.Login {

  if ($sock(ICHG)) {
    sockclose ICHG
  }
  unset %ICHG.cookie

  var %domain = $gettok(%ichg.domains,%ichg.scanningD,32) 
  if (%domain) {
    set %ICHG.forums $readini(MA.ini,n,%domain,forums)

    if ($numtok(%ICHG.forums,32) == 0) {
      echo -s $timestamp ICHG: No forums defined for %domain
      unset %ICHG.*
      return
    }

    sockopen ICHG %domain 80
    sockmark ICHG loginfetchpage /member.php?action=login
  }
  else {
    echo -s $timestamp ICHG: Domain not defined.
    unset %ICHG.*
  }
}

alias ICHG.scannew {

  if ($sock(ICHG)) {
    sockclose ICHG
  }
  if ($1 != 2) {

    inc %ICHG.scanningF 
    if (%ICHG.scanningF > $numtok(%ICHG.forums,32)) {
      inc %ICHG.scanningK
      if (%ICHG.scanningK > $numtok(%ICHG.keywords,32)) {
        inc %ICHG.scanningD
        if (%ICHG.scanningD > $numtok(%ICHG.domains,32)) {
          echo -s $timestamp ICHG: Blacklisting done. $calc(%ICHG.addsActual) / $calc(%ICHG.adds) names added.
          unset %ICHG.*
        }
        else {
          set -e %ICHG.scanningK 1
          set -e %ICHG.scanningF 1       
          ICHG.login
        }
        return
      }
      else {   
        set -e %ICHG.scanningF 1
      }
    }  

  }

  if (!$1 || $1 == 2) {
    unset %ICHG.newdomain
    sockopen ICHG $gettok(%ichg.domains,%ichg.scanningD,32) 80
    sockmark ICHG searchinit
  }
  else {
    .timerICHG 1 35 ICHG.scannew 2
  }

}
on 1:sockopen:ICHG:{
  if (!$sockerr) {  
    var %mark = $sock($sockname).mark
    var %domain = $gettok(%ichg.domains,%ichg.scanningD,32)

    if ($gettok(%mark,1,32) == movedinit) {

      sockmark $sockname NULL $gettok(%mark,2,32)
      sockwrite -n $sockname GET $gettok(%mark,3-,32) HTTP/1.1
      sockwrite -n $sockname Host: %domain
      sockwrite -n $sockname Connection: Close
      noop $ICHG.sendcookies($sockname)
      sockwrite -n $sockname $crlf
    }

    else if ($gettok(%mark,1,32) == logininit) {

      var %user = $readini(MA.ini,n,%domain,user)
      var %pass = $readini(MA.ini,n,%domain,pass)

      if (!%user || !%pass) {
        echo -s $timestamp ICHG: username or password not defined.
        sockclose $sockname
      }

      var %loginpost = action=do_login&url=&username= $+ %user $+ $chr(38) $+ password= $+ %pass $+ $iif($gettok(%mark,2-,32),$chr(38) $+ $v1,$null)

      sockmark $sockname NULL loginpost

      sockwrite -n $sockname POST /member.php HTTP/1.1
      sockwrite -n $sockname Host: %domain
      sockwrite -n $sockname Connection: Close

      sockwrite -n $sockname Content-Type: application/x-www-form-urlencoded
      sockwrite -n $sockname Content-Length: $len(%loginpost)
      sockwrite -n $sockname $crlf
      sockwrite -n $sockname %loginpost
    }
    else if ($gettok(%mark,1,32) == searchinit) {   

      sockmark $sockname NULL searchpost

      sockwrite -n $sockname POST /search.php HTTP/1.1 
      sockwrite -n $sockname Host: %domain
      sockwrite -n $sockname Connection: Close

      noop $ICHG.sendcookies($sockname)

      echo -s $timestamp ICHG: scanning keywords: $gettok(%ICHG.keywords,%ICHG.scanningK,32) forum: $gettok(%ICHG.forums,%ICHG.scanningF,32) site: %domain

      var %search = keywords= $+ $gettok(%ICHG.keywords,%ICHG.scanningK,32) $+ $chr(38) $+ action=do_search&forums= $+ $gettok(%ICHG.forums,%ICHG.scanningF,32) $+ $chr(38) $+ postthread=1  

      sockwrite -n $sockname Content-Type: application/x-www-form-urlencoded
      sockwrite -n $sockname Content-Length: $len(%search)
      sockwrite -n $sockname $crlf
      sockwrite -n $sockname %search
    }
    else if ($gettok(%mark,1,32) == searchnext || $gettok(%mark,1,32) == loginfetchpage) {   
      sockmark $sockname NULL $iif($gettok(%mark,1,32) == searchnext,searchpost,loginfetchpost)
      sockwrite -n $sockname GET $gettok(%mark,2-,32) HTTP/1.1
      sockwrite -n $sockname Host: %domain
      sockwrite -n $sockname Connection: Close
      noop $ICHG.sendcookies($sockname)
      sockwrite -n $sockname $crlf
    }

    else {
      echo -s $timestamp ICHG: Unknown socket status on sockopen: %mark
      sockclose $sockname
    }
  }
}
alias -l ICHG.sendcookies {
  if ($sock($1) && $len(%ICHG.cookie) > 0) {
    sockwrite -n $1 Cookie: %ICHG.cookie
  }
}
on 1:sockread:ICHG:{
  if (!$sockerr) {
    sockread -n %line
    while ($sockbr > 0) {   

      var %mark = $sock($sockname).mark

      if ($gettok(%line,1,32) == Set-Cookie:) {

        var %i = $numtok(%ICHG.cookie,$asc(;))
        var %cookiename = $gettok($gettok(%line,2,32),1,$asc(=))
        while (%i > 0) {
          var %cname = $gettok($gettok(%ICHG.cookie,%i,$asc(;)),1,$asc(=))
          if (%cname == %cookiename) {
            set %ICHG.cookie $deltok(%ICHG.cookie,%i,$asc(;))
          }

          dec %i
        }
        if ( $len( $gettok($left($gettok(%line,2,32),-1),2,$asc(=)) ) > 0 ) {
          set %ICHG.cookie $addtok(%ICHG.cookie,$left($gettok(%line,2,32),-1),$asc(;))
        }
      }

      if ($gettok(%mark,1,32) == NULL) {

        if ($gettok(%line,1-2,32) == HTTP/1.1 302) {
          sockmark $sockname moved_slink $gettok(%mark,2-,32)
          %mark = $sock($sockname).mark
        }
        else if (%line == HTTP/1.1 200 OK) {
          sockmark $sockname OK $gettok(%mark,2-,32)
          %mark = $sock($sockname).mark
        }  
        else if (%line ==  HTTP/1.1 404 Not Found) {
          sockclose $sockname
          echo -s ICHG: error 404: %mark
          ICHG.scannew 1
          return
        }  
      }
      else {  

        if ($gettok(%mark,1,32) == moved_slink) {
          if ($gettok(%line,1,32) == Location:) {
            var %site = http:// $+ $gettok(%ichg.domains,%ichg.scanningD,32)
            if ($left($gettok(%line,2,32),$len(%site)) == %site) {
              sockmark $sockname moved $gettok(%mark,2-,32) $htmldecode( $right($gettok(%line,2-,32),- $+ $len(%site)) )
              %mark = $sock($sockname).mark
            }
          }
        }

        else if ($gettok(%mark,1-2,32) == OK loginfetchpost) {
          if (<form> isin %line) {
            set -e %ICHG.form 1
          }

          if (%ICHG.form == 1) {
            if ($regex(%line,/name\=\"(.*?)\" .*?value\=\"(.*?)\"/) > 0) {

              var %ignorelist = action url username password 

              if ($len($regml(2)) > 0 && !$istok(%ignorelist,$regml(1),32)) {
                set -e %ICHG.LoginFormAdditionals $addtok(%ICHG.FormAdditionals,$regml(1) $+ = $+ $regml(2),38)
              }
            }
          }

          if (</form> isin %line) {
            unset %ICHG.form
          }
        }

        else if ($gettok(%mark,1-2,32) == OK searchpost) {

          if (!%ICHG.nextpage) {

            if (%line == %ICHG.nextpageText) {
              set -e %ICHG.nextpage 1
            }
            else {
              %line = $replace($striphtml(%line),ign,ign)
              %line = $replace(%line,in game name,ign)

              var %reg = /(.*)\bign([^0-9a-z_]*\b|\:|\()(.*)/
              if ($regex(%line,%reg) > 0) {      
                noop $ICHG.parseIGN( $regml(1),$regml(3) )  
              }
            }

          }
          else {
            unset %ICHG.nextpage

            if ($regex(%line,/a href\=\"(.*?)\"/) > 0) {
              var %link = / $+ $htmldecode($regml(1))
              var %page = $calc($gettok(%link,-1,61))
              if (%page > 1) {
                %link = $left(%link,- $+ $len(%page)) $+ $calc(%page -1)
                sockmark $sockname OK searchpost %link 
              }
            }
          }

        }
      }

      sockread -n %line
    }
  }
}
on 1:sockclose:ICHG:{
  var %mark = $sock($sockname).mark

  if ($gettok(%mark,1,32) == moved) {
    sockclose ICHG
    sockopen ICHG $gettok(%ichg.domains,%ichg.scanningD,32) 80
    sockmark ICHG movedinit $gettok(%mark,2-,32)
  }
  else if ($gettok(%mark,1,32) == OK) {
    sockclose ICHG
    if ($gettok(%mark,2,32) == loginpost) {
      ICHG.scannew
    }
    else if ($gettok(%mark,2,32) == loginfetchpost) {
      sockclose ICHG
      sockopen ICHG $gettok(%ichg.domains,%ichg.scanningD,32) 80
      sockmark ICHG logininit %ICHG.FormAdditionals
      unset %ICHG.FormAdditionals
    } 
    else if ($gettok(%mark,2,32) == searchpost) {

      %mark = $gettok(%mark,3-,32)
      if (!%mark) {
        ICHG.scannew 1
        return
      }

      if ($left($gettok(%mark,-1,38),4) == page) {
        %len = $len($gettok(%mark,-1,61))
        if (%len > 0) {
          %mark = $left(%mark,- $+ %len) $+ $calc($gettok(%mark,-1,61) +1)
        }
        else {
          echo -s $timestamp ICHG: Error while parsing next searchpage: %mark
          ICHG.scannew 1
          return
        }
      }
      else {
        %mark = %mark $+ $chr(38) $+ page=2
      }

      if ($calc($gettok(%mark,-1,61)) <= %ICHG.pagesToScan) {
        sockopen ICHG $gettok(%ichg.domains,%ichg.scanningD,32) 80
        sockmark ICHG searchnext %mark
      }
      else {
        ICHG.scannew 1
      }

    }
    else {
      echo -s $timestamp ICHG: Error with search. sockclosed with sockmark: %mark
    }
  }
  else {
    echo -s $timestamp ICHG: Error with search. sockclosed with sockmark: %mark
  }
}

alias -l ICHG.parseIGN {
  var %first  = $ICHG.parseIGN2($1)
  var %second = $ICHG.parseIGN2($2)

  %names = $gettok(%first,-1--3,32) $gettok(%second,1-4,32)

  var %i = 1
  while (%i <= $numtok(%names,32)) {
    if ($gettok(%names,%i,32) != %ICHG.lastName && !$istok( %ICHG.filter,$gettok(%names,%i,32),32) ) {
      set %ICHG.lastName $gettok(%names,%i,32)
      var %sql = INSERT into Blacklist ( Name ) VALUES ( $mysql_qt($mysql_real_escape_string(%ma.DB,%ICHG.lastName)) )
      if ($mysql_exec(%ma.DB, %sql)) {
        echo -s Added: %ICHG.lastName
        inc %ICHG.addsActual
      }
      ;echo -s gonna add: %ICHG.lastName
      inc %ICHG.adds

    }
    inc %i
  }
}

alias ICHG.parseIGN2 {
  var %text = $1-
  var %i = $numtok(%text,32)
  while (%i > 0) {
    var %tok = $gettok(%text,%i,32)
    var %ok = 0
    if ($len(%tok) >= 6) {
      if ($regex(%tok,[^\w]*([\w]*)[^\w]*) > 0) {        
        %match = $regml(1) 
        if ($len(%match) >= 6 && $len(%match) <= 16) {
          if ($regex(%match,([_0-9].?|^.[A-Z]|^.[cfqxz])) > 0 || $len(%match) >= 9) {
            %text = $reptok(%text,%tok,%match,0,32)
            %ok = 1
          }
        }
      }
    }
    if (%ok == 0) {
      %text = $deltok(%text,%i,32)
    }
    dec %i
  }
  return %text
}
alias striphtml {
  ; making sure there are parameters to work with
  IF ($1) {
    ; Setting my variables. The %opt is set kind of funky
    ; all it does is combine <two><brackets> into 1 <twobrackets>, fewer loops this way
    ; also stripped tab spaces
    VAR %strip,%opt = <> $remove($1-,> <,><,$chr(9)) <>,%n = 2
    ; using $gettok() I checked the text in front of '>' (chr 62)
    ; then the second $gettok checks the text behind '<' (chr 60)
    ; so I'm extracting anything between >text<
    WHILE ($gettok($gettok(%opt,%n,62),1,60)) {
      ; take each peice of text and add it to the same variable
      %strip = %strip $ifmatch
      ; increase the variable so the while statement can check the next part
      INC %n
    }
    ; now that the loop has finished we can return the stripped html code
    RETURN %strip
  }
}
alias htmldecode {
  if ($isid) return $regsubex($replace($1-,&quot;,",&amp;,&,&lt;,<,&gt;,>),/&#(\d+);/g,$chr($calc(\1 - 1264)))
  else echo -a $regsubex($replace($1-,&quot;,",&amp;,&,&lt;,<,&gt;,>),/&#(\d+);/g,$chr($calc(\1 - 1264)))
}
