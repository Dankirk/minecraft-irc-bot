; --------------------------------
; Minecraft Autoreply v1.1
;
; This is an autoreply script for fCraft's (custom Minecraft server) IRC bot(s)
; Gives answers to frequently asked questions on Minecraft server(s)
;
; Made by Dankirk
; --------------------------------

raw 330:*:{
  if (%ma.authing. [ $+ [ $2 ] ] ) {
    var %chan = $gettok(%ma.authing. [ $+ [ $2 ] ] ,1,32)
    if (%ma. [ $+ [ %chan ] $+ .botauth_set ] == $3) {
      set -eu5 %ma.authing. [ $+ [ $2 ] ] %chan 1 $3
    }
    haltdef
  }
}
raw 307:* is a registered nick:{
  if (%ma.authing. [ $+ [ $2 ] ] ) {
    var %chan = $gettok(%ma.authing. [ $+ [ $2 ] ] ,1,32)
    if (%ma. [ $+ [ %chan ] $+ .botauth_set ] == $2) {
      set -eu5 %ma.authing. [ $+ [ $2 ] ] %chan 1 $2
    }
    haltdef
  }
}
raw 311:*:{ if (%ma.authing. [ $+ [ $2 ] ] ) { haltdef } }
raw 319:*:{ if (%ma.authing. [ $+ [ $2 ] ] ) { haltdef } }
raw 312:*:{ if (%ma.authing. [ $+ [ $2 ] ] ) { haltdef } }
raw 317:*:{ if (%ma.authing. [ $+ [ $2 ] ] ) { haltdef } }

raw 318:*:{
  if (($2) && %ma.authing. [ $+ [ $2 ] ] ) {
    var %chan = $gettok(%ma.authing. [ $+ [ $2 ] ] ,1,32)
    if ($gettok(%ma.authing. [ $+ [ $2 ] ] ,2,32) == 1) {

      if (%chan) {
        set -e %ma. [ $+ [ %chan ] $+ .botauth ] $addtok(%ma. [ $+ [ %chan ] $+ .botauth ] , $2, 32)
        ;echo -s $timestamp MA BotAuth: $2 from %chan is authed.
      }
      else {
        echo -s $timestamp MA BotAuth: Failed %ma.authing. [ $+ [ $2 ] ] : $1-
      }
    }
    else {
      ;echo -s $timestamp MA BotAuth: $2 from %chan not authed.
    }
    unset %ma.authing. [ $+ [ $2 ] ]
    haltdef
  }
}

on *:INVITE:#:{
  if ($istok(%ma.servers,$chan,32)) {
    join $chan
  }
}


on 1:START:{
  ; Reset temporary variables
  unset %ma.#*.spam
  unset %ma.#*.spam.*
  unset %ma.#*.allowed
  unset %ma.DB
  unset %ma.#*.dbid
  unset %ma.curdate
  unset %ma.#*.botauth

  set %ma.datefrm yyyy-mm-dd

  if ($alias(themesongs.txt)) {
    themesongs.loadfiles
  }

  noop $ma.conDB()
}
alias ma.ConDB {

  echo -a MA: Initialising database connection...

  if (%ma.DB) {
    mysql_close %ma.DB
    unset %ma.DB
  }

  if ($isfile($scriptdir $+ MA.ini) && $isfile($scriptdir $+ mmysql.dll)) {
    var %host = $readini($scriptdir $+ MA.ini,Database,host)
    var %user = $readini($scriptdir $+ MA.ini,Database,user)
    var %pass = $readini($scriptdir $+ MA.ini,Database,pass)
    var %db = $readini($scriptdir $+ MA.ini,Database,db)

    set %ma.DB $mysql_connect(%host, %user, %pass)
    if (!%ma.DB) {
      echo -a MA: Failed connecting to %host
      return
    }

    if (!$mysql_select_db(%ma.DB, %db)) {
      echo -a MA: Failed selecting database %db
      mysql_close %ma.DB
      unset %ma.DB
      return
    }

    mysql_exec %ma.DB DELETE from Online

    noop $ma.updateSettings()
    noop $ma.DbDateCheck()

    ; Update Ranks
    var %maxserv = $numtok(%ma.servers,32)
    var %id = 1
    while (%id <= %maxserv) {
      var %servid = $ma.getServId($gettok(%ma.servers,%id,32))   
      if (%servid) {
        noop $ma.updateRanks(%servid)
      }
      inc %id
    }

    if (%ma.curdate) {
      echo -a MA: Database ready
      .timerma.DBUpdateEvent -o 0 600 ma.DBUpdateEvent   
      if ($sock(ma.websiteupd)) {
        .sockclose ma.websiteupd
      }
      if ($portfree(5665)) {
        .socklisten -d 127.0.0.1 ma.websiteupd 5665
      }
      else {
        echo -a Port 5665 wasn't open. Cannot receive settings update requests from website.
      }
    }

  }
  else {
    echo -a Files missing for MA Database conenction.
  }
}

alias -l ma.GetServName {
  if (%ma.db && $1 isnum) {
    var %sql = select name from Servers where id = $1
    return $ma.getDBline(%sql)
  }
  return $null
}
alias ma.DBUpdateEvent {
  if (%ma.DB) {

    ; Remove expired logins to website
    ;---------------------------------
    var %sql = delete from logins where (Created + INTERVAL 1 HOUR) < now()
    if (!$mysql_exec(%ma.DB,%sql)) {
      echo -s MA error DBUpdateEvent %mysql_errstr
      echo -s MA sql was: %sql
    }

    ; Remove expired kicks
    ;---------------------------------
    %sql = delete from kicks where (Timestamp + INTERVAL 2 DAY) < now()
    if (!$mysql_exec(%ma.DB,%sql)) {
      echo -s MA error DBUpdateEvent %mysql_errstr
      echo -s MA sql was: %sql
    }

    ; Mark timedout and remove old entries from online list
    ;--------------------------------
    %sql = delete from online where (timestamp + INTERVAL 12 HOUR) < now()
    if (!$mysql_exec(%ma.DB,%sql)) {
      echo -s MA error DBUpdateEvent %mysql_errstr
      echo -s MA sql was: %sql
    }

    ; Update server status
    ;--------------------------------
    var %i = $numtok(%ma.servers,32)
    while (%i > 0) {
      var %serv = $gettok(%ma.servers,%i,32)
      var %ok = 0
      if ($ma.IsOnChan(%serv)) {
        scid $v1
        var %y = $nick(%serv,0)
        while (%y > 0) {
          if ($nick(%serv,%y) != $me && $ma.is_servbot($nick(%serv,%y), %serv )) {
            %ok = 1
            mysql_exec %ma.DB UPDATE servers set IsOnline = $mysql_qt(ON) where id = $ma.getservid(%serv)
            break
          }
          dec %y
        }
      }
      if (%ok == 0) {
        mysql_exec %ma.DB UPDATE servers set IsOnline = $mysql_qt(OFF) where id = $ma.getservid(%serv)
      }
      dec %i
    }

    ; Check for rank errors
    ;---------------------------------
    %sql = select id, servers.name as servname, count(server) as errs from rankerrors inner join servers on id=server group by server
    var %res = $mysql_query(%ma.DB, %sql)
    if (%res) {
      while ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
        var %id = $hget(row, id)
        var %serv = $hget(row, servname)
        var %errs =  $hget(row, errs)

        if (%errs > 3 && %ma. [ $+ [ %serv ] $+ .rank_set ] && %ma. [ $+ [ %serv ] $+ .AutoDisableRanks ] ) {
          set %ma. [ $+ [ %serv ] $+ .rank_set ] 0
          mysql_exec %ma.DB update servers set Ranks=0 where id = %id
          if ($ma.IsOnChan(%serv)) {
            scid $v1
            echo -s disabled ranks for %serv
            ma.msg %serv My rank settings don't match the server's settings. Disabling rank detection.
          }         
        }
      } 
      mysql_free %res
    }

    else {
      echo -s MA error DBUpdateEvent %mysql_errstr
      echo -s MA sql was: %sql
    }

  }
  else {
    .timerma.DBUpdateEvent off
  }
}

alias ma.DBDateCheck {
  if (%ma.curdate != $date(%ma.datefrm) && %ma.DB) {  
    var %maxserv = $numtok(%ma.servers,32)
    var %id = 1
    var %date = $date(%ma.datefrm)
    while (%id <= %maxserv) {
      var %serv = $ma.getServId($gettok(%ma.servers,%id,32))
      if (%serv) {
        var %sql = SELECT date from Stats where date = $mysql_qt($mysql_real_escape_string(%ma.DB,%date)) AND Server = %serv 
        if (!$ma.getDBline(%sql)) {
          %sql = INSERT into Stats (Date,Server) VALUES ( $mysql_qt($mysql_real_escape_string(%ma.DB,%date)) , %serv )
          if (!$mysql_exec( %ma.DB, %sql ) ) {
            echo -s MA error ma.dbdatecheck %mysql_errstr
          }
        }
      }
      inc %id
    }
    set -e %ma.curdate %date

    ; Update blacklist
    ; iCanHasGrief
  }
}

; --------------------------------
; Feature for checking if any joining player is hacked by the 15th March 2011 incident
; --------------------------------
on 1:sockopen:ma.hackinform.*:{
  if ($sockerr) {
    noop $ma.hackretry($sockname)
    return
  }
  ma.open_hackcheck $sockname
}
alias -l ma.open_hackcheck {
  if ($1) {
    ; website: https://haveibeenpwned.com/api/v2/breachedaccount/
    var %mark = $sock($1).mark

    if ($sock($1).wserr == 0 && $numtok(%mark,32) == 4) {
      echo -a hackinform: requesting info for: $gettok(%mark,1,32)
      sockwrite -n $1 GET /api/v2/breachedaccount/ $+ $urlencode($gettok(%mark,1,32)) HTTP/1.1
      sockwrite -n $1 User-Agent: Minecraft-Autoreply-bot-Dankirk
      sockwrite -n $1 Host: haveibeenpwned.com
      sockwrite -n $1 Connection: close
      sockwrite -n $1 $crlf
    }
    else if ($numtok(%mark,32) == 4) {
      ;echo -s MA: Retrying hackcheck for $gettok(%mark,1,32)
      noop $ma.hackretry($1)
    }
    else {
      echo -s MA: Invalid sockmark on hackcheck: %mark
      sockclose $1
    }
  }
}

alias -l ma.hackretry {
  return
  var %mark = $sock($1).mark
  var %retry = $iif($calc($gettok(%mark,3,32)) > 0,$v1,1)

  if (%retry < 3) {   
    sockclose $1 

    inc %retry
    sockopen -e $1 haveibeenpwned.com 443
    sockmark $1 $gettok(%mark,1-2,32) %retry 0
  }
  else {
    echo -s $timestamp MA.Hackinform connection error after 3 retries. Param: %mark
    noop $ma.hackinformfail(1)
  }
  return %retry
}
alias -l ma.hackinformfail {
  if (%ma.hackinformCheck < 5) {
    set -eu1500 %ma.hackinformCheck $calc($calc(%ma.hackinformCheck) + 1)
  }
  if (%ma.hackinformCheck == 5) {  
    set -eu7200 %ma.hackinformCheck 6
    echo -s $timestamp MA.Hackinform Informing about problem with haveibeenpwned.com
    ma.tell It seems there's a problem with haveibeenpwned.com. Retrying hacked account checks in 2 hours.
  }
}

on 1:sockread:ma.hackinform.*:{

  if ($sockerr) {
    echo -s MA.Hackinform sockread error. Param: $sock($sockname).mark
    noop $ma.hackretry($sockname)
    return
  }

  var %http_ok = HTTP/1.1 200 OK
  var %http_notfound = HTTP/1.1 404 Not found
  var %nick = $gettok($sock($sockname).mark,1,32)
  var %chan = $gettok($sock($sockname).mark,2,32)
  var %jsonstart = 31a
  var %ok = 0

  var %data
  sockread -n %data

  if ($gettok($sock($sockname).mark,4,32) == 0) {

    if (%http_ok isin %data) {
      sockmark $sockname $gettok($sock($sockname).mark,1-3,32) 1
      echo -a hackinform: found!
    }
    else if (%http_notfound isin %data) {
      sockmark $sockname $gettok($sock($sockname).mark,1-3,32) 2
      echo -a hackinform: not found
      return
    }
    else {
      echo -s $timestamp MA.Hackinform HTTP response not OK. Param: $sock($sockname).mark
      noop $ma.hackretry($sockname)
      return
    }
  }
  else if ($gettok($sock($sockname).mark,4,32) == 1) {

    while ($sockbr && %ok == 0) {

      echo -a read: %data
      if (%jsonstart == %data) {
        %ok = 1
        sockread -n %data

      }
      else if (%ok == 1) {
        echo -a the data: %data
        %ok = 2
      }
      sockread -n %data
    }

    if (%ok != 0) {
      sockmark $sockname $gettok($sock($sockname).mark,1-3,32) 2
      ;  echo -s hackinform ready: $sock($sockname).mark
      unset %ma.hackinformCheck
    }
    if (%ok == 2) {
      if (!%ma.hackinform. [ $+ [ %chan ] $+ [ $chr(46) ] $+ [ %nick ] ] ) {

        set %ma.hackinform. [ $+ [ %chan ] $+ [ $chr(46) ] $+ [ %nick ] ] 1
        if (%ma.DB) {
          noop $mysql_exec(%ma.DB,UPDATE Servers set Hackinforms = (Hackinforms + 1) WHERE name = $mysql_qt($mysql_real_escape_string(%ma.DB,%chan)) )
        }
        echo -s $timestamp MA.Hackinform warned %nick for compromised account at %chan      

        ma.hackinform %chan 1 %nick
        .timerma. $+ %chan $+ .hackinform. $+ %nick -o 1 30 ma.hackinform %chan 2 %nick 
      }
    }
  }
}

alias -l ma.hackinform {
  if ($0 == 3 && $me ison $1) {
    ma.msg $1 Warn $2 $+ /2: $3 $+ 's account has been compromised! Reference: https://haveibeenpwned.com/api/v2/breachedaccount/ $+ $urlencode($3)
  }
}

on 1:sockclose:ma.hackinform.*:{
  var %sockname = $sockname
  var %mark = $sock(%sockname).mark
  if ($gettok(%mark,-1,32) != 2) {
    if ($ma.hackretry(%sockname) > 3) {
      if ( $gettok(%mark,-1,32) == 1) {
        echo -s $timestamp Hackinform: haveibeenpwned.com has been changed, cannot verify nicknames
      }
    }
  }
}

alias ma.hackcheck {

  echo -a checking $1

  ; mIRC JSON parser provided by SReject
  JSONOpen -dwu ma_pwntest2 https://haveibeenpwned.com/api/v2/breachedaccount/ $+ $urlencode($1) $+ ?truncateResponse=true
  JSONUrlMethod ma_pwntest2 GET
  JSONUrlHeader ma_pwntest2 User-Agent: Minecraft-Autoreply-bot-Dankirk
  JSONUrlGet ma_pwntest2

  if ($json(ma_pwntest2).UrlStatus == 200) {
    var %i = $calc($json(ma_pwntest2).length - 1)
    while (%i >= 0) {
      if ($json(ma_pwntest2,%i,Name) == Minecraft || $json(ma_pwntest2,%i,Title) == Minecraft || $json(ma_pwntest2,%i,Name) == HeroesOfNewerth) {
        echo -a Account: $1 is hacked.
        return
      }
      dec %i
    }
    echo -a Account: $1 found, but not hacked.
  }
  else {
    echo -a hackcheck statuscode: $json(ma_pwntest2).UrlStatus error: $json(ma_pwntest2).error
  }
}
alias -l ma.init_hackcheck {

  if ($ma.IsOnChan($1) && $numtok($2,32) == 1 && $len($2) >= 3 && $len($2) <= 16 && $chr(46) !isin $2 && @ !isin $2) {
    scid $ma.IsOnChan($1)
    if ($calc(%ma.hackinformCheck) < 5 && (!%ma.hackinform. [ $+ [ $1 ] $+ [ $chr(46) ] $+ [ $2 ] ] )) {

      var %chan = $1
      var %nick = $2

      if ($json(ma_pwntest) || %ma.hackcheckthrottle) {
        .timer 1 3 ma.init_hackcheck %chan %nick
        return
      }

      echo -s $timestamp MA.Hackinform: testing %nick on %chan

      ; mIRC JSON parser provided by SReject
      JSONOpen -dwu ma_pwntest https://haveibeenpwned.com/api/v2/breachedaccount/ $+ $urlencode(%nick) $+ ?truncateResponse=true
      JSONUrlMethod ma_pwntest GET
      JSONUrlHeader ma_pwntest User-Agent: Minecraft-Autoreply-bot-Dankirk
      JSONUrlGet ma_pwntest

      var %http_response = $json(ma_pwntest).UrlStatus
      var %json_error = $json(ma_pwntest).error

      ; Throttled
      if (%http_response == 429) {
        echo -s $timestamp MA.Hackinform throttling %nick on %chan
        set -eu2 %ma.hackcheckthrottle 1
        .timer 1 3 ma.init_hackcheck %chan %nick
      }

      ; Found!
      else if (%http_response == 200) {
        var %i = $calc($json(ma_pwntest).length - 1)
        while (%i >= 0) {
          if ($json(ma_pwntest,%i,Name) == Minecraft) {
            ;if ($json(ma_pwntest,%i,Name) == Minecraft || $json(ma_pwntest,%i,Title) == Minecraft) {

            set %ma.hackinform. [ $+ [ %chan ] $+ [ $chr(46) ] $+ [ %nick ] ] 1
            if (%ma.DB) {
              noop $mysql_exec(%ma.DB,UPDATE Servers set Hackinforms = (Hackinforms + 1) WHERE name = $mysql_qt($mysql_real_escape_string(%ma.DB,%chan)) )
            }
            echo -s $timestamp MA.Hackinform warned %nick for compromised account at %chan      

            ma.hackinform %chan 1 %nick
            .timerma. $+ %chan $+ .hackinform. $+ %nick -o 1 30 ma.hackinform %chan 2 %nick 

            return

          }
          dec %i
        }
        echo -s $timestamp MA.Hackinform %nick on %chan isn't hacked, but was found on db.
      }

      ; Error
      else if (%http_response != 404) {
        echo -s $timestamp MA.Hackinform httpcode: %http_response error: %json_error nick: %nick 
      }

      return
      ; Old behaviour below this point

      ; Check if connecting player is a victim of the minecraft account hack (max 10 checks at time)
      var %id = 1
      while (%id < 10) {
        var %status = $gettok($sock(ma.hackinform. $+ %id).mark,-1,32) 
        if (!$sock(ma.hackinform. $+ %id) || %status == 2) {
          break
        }
        inc %id
      }

      if (%id <= 10) {

        var %newsock = ma.hackinform. $+ %id

        ;  echo -s hackinform init: $2 $1 1 0

        if (!$sock(%newsock)) {
          sockopen -e %newsock haveibeenpwned.com 443
          sockmark %newsock $2 $1 1 0
        }
        else {
          sockmark %newsock $2 $1 1 0
          ma.open_hackcheck %newsock
        }
      }
      else {
        echo -s Hackinform: Too crowded (10 simultaneous requests)
      }
    }
    else if (%ma.hackinform. [ $+ [ $1 ] $+ [ $chr(46) ] $+ [ $2 ] ] && $calc(%ma.hackinform. [ $+ [ $1 ] $+ [ $chr(46) ] $+ [ $2 ] ] ) < 3) {
      inc %ma.hackinform. [ $+ [ $1 ] $+ [ $chr(46) ] $+ [ $2 ] ]
      ma.msg $1 $2 has been warned of compromised account before. 
    }
  }
}

; Get Server ID
alias ma.getServID {
  if ($len($1) > 0 && %ma.DB) {
    if (%ma. [ $+ [ $1 ] $+ .dbid ] ) {
      return $v1
    }
    else {    
      var %servid = $ma.getDBline(SELECT id FROM Servers WHERE Name = $mysql_qt($mysql_real_escape_string(%ma.DB,$1)) )     
      set %ma. [ $+ [ $1 ] $+ .dbid ] %servid
      return %servid
    }
  }
  return $null
}

; Syntax: $1 = serverID, $2 = opName
alias ma.GetOpID {
  if (($numtok($2,32) >= 1) && (%ma.DB)) {
    var %sql_query = select id from Ops WHERE Server = $1 AND Name = $mysql_qt($mysql_real_escape_string(%ma.DB,$2))
    var %opid = $ma.getDBline(%sql_query)
    if (!%opid && $3 != 1) {
      var %sql = INSERT INTO Ops (Server,Name) VALUES ( $1 , $mysql_qt($mysql_real_escape_string(%ma.DB,$2)) ) 
      if (!$mysql_exec(%ma.DB, %sql)) {
        echo -a MA err ma.GetOpID %mysql_errstr
      }
      %opid = $ma.getDBline(%sql_query)
    }  
    return %opid
  }
  return $null
}

; Fetch a single column of a single row
alias ma.getDBline {
  if ($1) {
    var %res = $mysql_query(%ma.DB, $1-)
    if (%res) {
      var %ret = $iif($calc($mysql_num_rows(%res)) > 0,$mysql_fetch_single(%res),$null)
      mysql_free %res
      return %ret
    }
    else {
      echo -s Err ma.getDBline %mysql_strerr
      echo -s Query was: $1-
    }

  }
  return $null
}

alias ma.FindAuthServBot {
  if ($1 && $me ison $1 && $len(%ma. [ $+ [ $1 ] $+ .botauth_set ] ) > 0) {
    var %i = $nick($1,0)
    var %matches = 0
    while (%i > 0) {
      if ($nick($1,%i) != $me) {
        if ($ma.is_servbot($nick($1,%i),$1,1)) {
          set -eu8 %ma.authing. [ $+ [ $nick($1,%i) ] ] $1 0
          whois $nick($1,%i)
          inc %matches
        }
      }

      ; If too many servbot matches, invalidate everyone
      if (%matches > 4) {
        echo -s $timestamp MA: Too many auth matches at $1
        unset %ma.authing. [ $+ [ $nick($1,%i) ] ]
        unset %ma. [ $+ [ $1 ] $+ .botauth ]
        return
      }
      dec %i
    }
    if (%matches > 0) {
      ; TODO servbot online 
    }
  }
}

alias ma.authall {
  unset %ma.#*.botauth
  var %i = $numtok(%ma.servers,32)
  while (%i >= 1) {
    scon -a ma.FindAuthServBot $gettok(%ma.servers,%i,32)
    dec %i
  }
}

on me:*:JOIN:#:{

  if (!%ma.servers) {
    echo -s MA debug: ma.servers not initialized yet.
  }

  if ($istok(%ma.servers,$chan,32) && !$timer(ma.reauth. $+ %chan)) {
    unset %ma. [ $+ [ $chan ] $+ .botauth ]
    mysql_exec %ma.DB DELETE from Online where server = $ma.getservid($chan)
    .timerma.reauth. $+ $chan 1 3 ma.FindAuthServBot $chan
  }

  ; New Server request
  else if ($gettok(%ma.newserver,3,32) == $chan && $gettok(%ma.newserver,1,32) == 2) {
    var %botname = $gettok(%ma.newserver,4,32)
    ; if (%botname !isvoice $chan && %botname !isop $chan && %botname !ishop $chan) {
    if (1 != 1 && %botname !ison $chan) {
      set -eu60 %ma.newserver -1 $gettok(%ma.newserver,2-,32)
      msg $gettok(%ma.newserver,2,32) %botname must be on $chan
      part $chan
    }
    else {
      set -eu60 %ma.newserver 3 $gettok(%ma.newserver,2-,32)
      ma.CreateNewServer_2 $gettok(%ma.newserver,3,32) 1 %botname
    }
  }
}

on *:JOIN:#:{
  if ($istok(%ma.servers,$chan,32) && $ma.is_servbot($nick,$chan,1)) {
    ; mysql_exec %ma.DB DELETE from Online where server = $ma.getservid($chan)

    if ($len(%ma. [ $+ [ $chan ] $+ .botauth_set ] ) > 0) {
      var %id = 1
      while ($timer(ma.OnJoinAuth. $+ %id)) {
        inc %id
      }
      .timerma.OnJoinAuth. $+ %id 1 3 ma.OnJoinAuth $nick $chan
    }
    else if ($me isop $chan) {
      mode $chan +v $nick
    }
  }
}
alias -l ma.SetServerOnline {
  ; TODO server online status
}
alias -l ma.OnJoinAuth {
  set -eu8 %ma.authing. [ $+ [ $1 ] ] $2 0
  whois $1
}

on *:NICK:{
  var %i = 1
  while (%i <= $comchan($newnick,0)) {
    var %chan = $comchan($newnick,%i)
    if ($istok(%ma.servers,%chan,32) && %ma. [ $+ [ %chan ] $+ .botauth_set ] ) {
      if ($ma.is_servbot($newnick,%chan,1)) {
        if (!$timer(ma.reauth. $+ %chan)) {
          .timerma.reauth. $+ %chan 1 5 ma.FindAuthServBot %chan
        }
      }
    }
    inc %i
  }
}
on *:PART:#:{
  if ($istok(%ma.servers,$chan,32) ) {
    if ($nick == $me) {
      unset %ma. [ $+ [ $chan ] $+ .botauth ]
      mysql_exec %ma.DB DELETE from Online where server = $ma.getservid($chan)
    }
    else if ($ma.is_servbot($nick,$chan)) {
      set -e %ma. [ $+ [ $chan ] $+ .botauth ] $remtok(%ma. [ $+ [ $chan ] $+ .botauth ] ,$nick,0,32)
      mysql_exec %ma.DB DELETE from Online where server = $ma.getservid($chan)
    }
  }
}
on *:KICK:#:{
  if ($istok(%ma.servers,$chan,32)) {
    if ($knick == $me) {
      unset %ma. [ $+ [ $chan ] $+ .botauth ]
      mysql_exec %ma.DB DELETE from Online where server = $ma.getservid($chan)
    }
    else if ($ma.is_servbot($knick,$chan)) {
      set -e %ma. [ $+ [ $chan ] $+ .botauth ] $remtok(%ma. [ $+ [ $chan ] $+ .botauth ] ,$knick,0,32)
      mysql_exec %ma.DB DELETE from Online where server = $ma.getservid($chan)
    }
  }
}
on *:QUIT:{
  var %i = 1
  while (%i <= $comchan($nick,0)) {
    var %chan = $comchan($nick,%i)
    if ($istok(%ma.servers,%chan,32)) {
      if ($ma.is_servbot($nick,%chan) ) {
        set -e %ma. [ $+ [ %chan ] $+ .botauth ] $remtok(%ma. [ $+ [ %chan ] $+ .botauth ] ,$nick,0,32)
        mysql_exec %ma.DB DELETE from Online where server = $ma.getservid(%chan)
      }
    }
    inc %i
  }
}

;--------------------------------
; Event replying (and recording)
;--------------------------------
on *:ACTION:*:#:{

  if (!$istok(%ma.servers,$chan,32)) {
    return
  }

  var %text = $strip($1-)

  if (%ma. [ $+ [ $chan ] $+ .impersonation ] && (!%ma. [ $+ [ $chan ] $+ .mute ] ) && ($ma.is_servbot($nick,$chan)) && (!%ma. [ $+ [ $chan ] $+ .spam ] ) ) {
    var %irc = (IRC)
    var %tok = 0
    if ($gettok(%text,1,32) == %irc && $right($gettok(%text,2,32),1) == :) {
      %tok = 2
    }
    else if ($right($gettok(%text,1,32),1) == :) {
      %tok = 1
    }

    if (%tok > 0) {
      set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1
      if ($gettok(%text,%tok,32) == $me $+ :) { 
        ma.msg $chan That wasn't me O_o    
      }
      else {
        ma.msg $chan That wasn't real $left($gettok(%text,%tok,32),-1)
      }
      return
    }
  }

  ; Verify we are receiving messages in proper format (The format bots are using)
  if (!%ma. [ $+ [ $chan ] $+ .mute ] && ($ma.is_servbot($nick,$chan)) && $gettok(%text,1,32) == $chr(42)) {

    ; var %nick = $gettok($gettok($strip($1-,bur),2-,32),1,58) 
    ; var %nick =  $gettok($strip($1-,bur),2,32)

    var %servid = $ma.getServID($chan)
    noop $ma.DBDateCheck()


    ; CONNECTED
    ;;;;;;;;;;;;;;;;;;
    if ($regex(%text,/^\* (.*?) connected\.$/) == 1) {

      if ($numtok($regml(1),32) >= 1) {

        var %nick = $gettok($strip($1-,bur),2 - $calc($numtok($strip($1-,bur),32) -1), 32)
        var %isbanned = $iif($left($strip(%nick),1) == * && $left($gettok(%nick,-2,3),3) == 04*,1,0)

        var %rank = $calc($ma_getrank(%nick,$chan))
        var %rankinfo = $gettok($ma_getrank(%nick,$chan,1),1,32)

        %nick = $ma_getnick($strip(%nick))
        if (%nick == unknown) {
          echo -s NICK ERROR connect: $timestamp $chan $strip($1-) 2: $gettok($strip($1-,bur),2,32) 3: $gettok($strip($1-,bur),3,32) 
        }

        ;echo $chan caught: $timestamp $chan %nick connected. %isbanned da $iif(!%isbanned && %nick,1,0)

        if (!%isbanned && %nick && %nick != unknown) {

          noop $ma.setOnline($chan,1,%rank,%nick)

          if (%servid) {
            mysql_exec %ma.DB UPDATE Servers Set Visitors = Visitors + 1 WHERE id = %servid
            mysql_exec %ma.DB UPDATE Stats Set Visitors = Visitors + 1 WHERE Server = %servid AND Date = $mysql_qt( $mysql_real_escape_string(%ma.DB,$date(%ma.datefrm)) )

            if (%ma. [ $+ [ $chan ] $+ .rank_set ] ) {
              var %tmpnick = $gettok($strip($1-,bur),2,32) 
              var %ret = $ma_getrank(%tmpnick,$chan,1)
              if ($gettok(%ret,1,32) >= 0) {
                mysql_exec %ma.DB UPDATE RankedVisitors Set num = num + 1 WHERE Server = %servid AND Color = $gettok(%ret,1,32) AND Prefix = $mysql_qt($mysql_real_escape_string(%ma.DB,$gettok(%ret,2,32)))
              }
            }

            var %curvis = $ma.getDBline(SELECT visitors from Servers WHERE id = %servid )
            if ($len(%curvis) > 4 && $right(%curvis,4) == 0000) {
              ma.msg $chan Congrats %nick $+ ! You are our %curvis $+ th visitor since I started counting them in $ma.GetFirstDate($chan)
            }

            if (%rankinfo != -3) {
              if (%nick && $ma.getDBline(SELECT Name from Blacklist WHERE Name = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick)) ) == %nick) {
                echo -s $timestamp blacklist warn on $chan for %nick
                ma.msg $chan %nick might be associated with grief group iCanHasGrief.
              }
            }

          }
          if (%rankinfo != -3) {
            ;noop $ma.init_hackcheck($chan,%nick)
          }
        }
      }
    }

    ; KICKED
    ;;;;;;;;;;;;;
    else if ($regex(%text,/^\* (.*?) was kicked by (.*?) Reason: .*$/) == 1 || $regex(%text,/^\* (.*?) was kicked by (.*)$/) == 1) {

      var %tmpnick = $regml(1)
      var %tmpkicker = $regml(2)
      var %nick = $replace($ma_getnick(%tmpnick),$chr(32),$chr(44))
      var %kicker = $ma_getnick(%tmpkicker)

      if (%nick == unknown || %kicker == unknown) {
        echo -s NICK ERROR kicked: $timestamp $chan $1-
      }

      if ($numtok(%nick,32) == 1 && $timer(ma. $+ $chan $+ .hackinform. $+ %nick )) {
        .timerma. $+ $chan $+ .hackinform. $+ %nick off
      }

      ;noop $ma.setOnline($chan, $calc($ma_getrank($strip(%tmpkicker,bur),$chan)) ,%kicker)

      var %sql = select count from Kicks where Server = %servid and Name = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick))
      var %count = $calc($ma.getDBline(%sql))
      if (%count >= 1) {
        mysql_exec %ma.DB UPDATE Kicks set count = $calc(%count + 1) where Server = %servid and Name = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick))
        if ($calc(%count + 1) > 3 && !%ma. [ $+ [ $chan ] $+ .spam ] ) {
          set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1
          ma.msg $chan %nick has been kicked $calc(%count + 1) times within 6 days. A ban might be in order.
        }
      }
      else {
        mysql_exec %ma.DB INSERT into Kicks (Name,Server) VALUES ( $mysql_qt($mysql_real_escape_string(%ma.DB,%nick)) , %servid )
      }


      if (%servid) {

        mysql_exec %ma.DB DELETE from Online where server = %servid AND PlayerName = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick))

        mysql_exec %ma.DB UPDATE Servers set Kicks = Kicks + 1 WHERE id = %servid
        mysql_exec %ma.DB UPDATE Stats Set Kicks = Kicks + 1 WHERE Server = %servid AND Date = $mysql_qt( $mysql_real_escape_string(%ma.DB,$date(%ma.datefrm)) )

        var %opid = $ma.getOpID( %servid, %kicker )
        if (%opid) {
          mysql_exec %ma.DB UPDATE Ops Set Kicks = Kicks + 1 WHERE id = %opid
        }

      }
    }

    ; BANNED
    ;;;;;;;;;;;;;;;;;;;;;;;
    else if ($regex(%text,/^\* (.*?) was banned by (.*?) Reason: .*$/) == 1 || $regex(%text,/^\* (.*?) was banned by (.*)$/) == 1 || $regex(%text,/^(?:\* )?(.*?) was BanX\'d by (.*?)\(with auto-demote\): .*$/) == 1 || $regex(%text,/^(?:\* )?(.*?) was BanX\'d \(with auto-demote\) by (.*?) Reason: .*$/) == 1 || $regex(%text,/^(?:\* )?(.*?) was BanX\'d by (.*?) Reason: .*$/) == 1) {

      var %tmpnick = $regml(1)
      var %tmpbanner = $regml(2)
      var %nick = $ma_getnick(%tmpnick)
      var %nick_sr = $replace(%nick,$chr(32),$chr(44))
      var %banner = $ma_getnick(%tmpbanner))

      if (%nick == unknown || %banner == unknown) {
        echo -s NICK ERROR banned: $timestamp $chan $1-
      }

      ;noop $ma.setOnline($chan, $calc($ma_getrank($strip(%tmpbanner,bur),$chan)) ,%banner)

      if ($numtok(%nick,32) == 1 && $timer(ma. $+ $chan $+ .hackinform. $+ %nick )) {
        .timerma. $+ $chan $+ .hackinform. $+ %nick off
      }

      mysql_exec %ma.DB DELETE from Online where server = %servid AND PlayerName = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick))
      mysql_exec %ma.DB DELETE from Kicks where Server = %servid and Name = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick))

      if (%servid) {
        mysql_exec %ma.DB UPDATE Servers set Bans = Bans + 1 WHERE id = %servid
        mysql_exec %ma.DB UPDATE Stats Set Bans = Bans + 1 WHERE Server = %servid AND Date = $mysql_qt( $mysql_real_escape_string(%ma.DB,$date(%ma.datefrm)) )

        var %opid = $ma.getOpID( %servid, %banner )
        if (%opid) {
          mysql_exec %ma.DB UPDATE Ops Set Bans = Bans + 1 WHERE id = %opid
        }  

        %opid = $ma.getDBline( select Promoter from Promoted where Name = $mysql_qt( %nick ) AND Server = %servid )
        if (%opid) {
          mysql_exec %ma.DB UPDATE Ops Set Promobfires = Promobfires + 1 WHERE id = %opid
          mysql_exec %ma.DB DELETE FROM Promoted where Server = %servid AND Name = $mysql_qt( $mysql_real_escape_string(%ma.DB,%nick) )
        }
      }
    }
    ; UNBANNED
    ;;;;;;;;;;;;;;;;;;;;;;;
    else if ($regex(%text,/^\* (.*?) was unbanned by (.*?) Reason: .*$/) == 1 || $regex(%text,/^\* (.*?) was unbanned by (.*)$/) == 1) {
    }

    ; LEFT SERVER
    ;;;;;;;;;;;;;
    else if ($regex(%text,/^\* (.*?) left the (server|game)/) == 1 || $regex(%text,/^([^:]*?) Ragequit from the server/) == 1) {

      var %nick = $ma_getnick($regml(1))

      if (%nick == unknown) {
        echo -s NICK ERROR left: $timestamp $chan $1-
      }

      if ($numtok(%nick,32) == 1 && $timer(ma. $+ $chan $+ .hackinform. $+ %nick )) {
        .timerma. $+ $chan $+ .hackinform. $+ %nick off
      }
      mysql_exec %ma.DB DELETE from Online where server = %servid AND PlayerName = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick))
    }

    ; PROMOTED
    ;;;;;;;;;;;;;;;;
    else if ($regex(%text,/^\* (.*?) was (Auto)?Promoted from .*? to .*? by (.*?) Reason: .*$/) == 1 || $regex(%text,/^\* (.*?) was (Auto)?Promoted from .*? to .*? by (.*?)$/) == 1) {
      var %auto = $iif($regml(2) == Auto,1,0)
      var %tmppromo = $regml($iif(%auto == 1,3,2))
      var %nick = $ma_getnick($regml(1)) 

      if (%nick == unknown) {
        echo -s NICK ERROR promoted: $timestamp $chan $1-
      }

      if (%servid) {

        if ($ma.getDBline(SELECT Name from Blacklist WHERE Name = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick)) ) == %nick) {
          echo -s blacklist warn on $chan for %nick
          ma.msg $chan %nick might be associated with grief group iCanHasGrief.
        }

        var %promoter = $iif($ma_getnick(%tmppromo),$v1,console)

        if (%promoter == unknown) {
          echo -s NICK ERROR promoter: $timestamp $chan $1-
        }

        mysql_exec %ma.DB UPDATE Servers set Promotes = Promotes + 1 WHERE id = %servid
        mysql_exec %ma.DB UPDATE Stats Set Promotes = Promotes + 1 WHERE Server = %servid AND Date = $mysql_qt( $mysql_real_escape_string(%ma.DB,$date(%ma.datefrm)) )

        if (%auto == 0) {

          var %promotedID = $ma.getDBLine(SELECT id from Promoted where server = %servid AND name = $mysql_qt( $mysql_real_escape_string(%ma.DB,%nick) ) )
          var %promoterID = $ma.getOpID( %servid, %promoter )

          if (%promoterID) {
            mysql_exec %ma.DB UPDATE Ops Set Promotes = Promotes + 1 WHERE id = %promoterID

            if (%promotedID) {  
              mysql_exec %ma.DB UPDATE Promoted set Promoter = %promoterID WHERE id = %promotedID
            }
            else {
              mysql_exec %ma.DB insert into Promoted (Name,Server,Promoter) VALUES ( $mysql_qt( $mysql_real_escape_string(%ma.DB,%nick) ) , %servid , %promoterID )
            }
          }
        }

      }

      if ($ma.getDBline(SELECT PlayerName from Online where server = %servid and PlayerName = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick)) )) {
        set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1
        if ($chan == #fcraft.server && $gettok(%text,8,32) == builder) {
          ma.msg $chan %nick $+ , Congratulations on your new rank! Type /j school to learn the cuboid command.
        }
        else {
          ma.msg $chan %nick $+ , Congratulations on your new rank!
        }
      }
    }

    ; DEMOTED
    ;;;;;;;;;;;;;;;;
    else if ($regex(%text,/^\* (.*?) was (Auto)?Demoted from .*? to .*? by (.*?) Reason: .*$/) == 1 || $regex(%text,/^\* (.*?) was (Auto)?Demoted from .*? to .*? by (.*)$/) == 1) {

      if (%servid) {

        mysql_exec %ma.DB UPDATE Servers set Demotes = Demotes + 1 WHERE id = %servid
        mysql_exec %ma.DB UPDATE Stats Set Demotes = Demotes + 1 WHERE Server = %servid AND Date = $mysql_qt( $mysql_real_escape_string(%ma.DB,$date(%ma.datefrm)) )
        var %tmpdemo = $iif($regml(0) == 3,$regml(3),$regml(2))
        var %nick = $ma_getnick($regml(1))        
        var %demoter = $iif($ma_getnick(%tmpdemo),$v1,console)
        ;echo -s $timestamp MA: debug demote %nick by %demoter at $chan

        if (%nick == unknown || %demoter == unknown) {
          echo -s NICK ERROR demoted: $timestamp $chan $1-
        }

        var %promoterID = $ma.getDBLine(SELECT Promoter from Promoted where server = %servid AND name = $mysql_qt( $mysql_real_escape_string(%ma.DB,%nick) ) )
        var %demoterID = $ma.getOpID( %servid, %demoter )

        if (%demoterID) {
          mysql_exec %ma.DB UPDATE Ops Set Demotes = Demotes + 1 WHERE id = %demoterID

          if (%promoterID) {  
            mysql_exec %ma.DB UPDATE Ops Set Promobfires = Promobfires + 1 WHERE id = %promoterID
            mysql_exec %ma.DB DELETE FROM Promoted where Server = %servid AND Name = $mysql_qt( $mysql_real_escape_string(%ma.DB,%nick) )
          }
        }
        ;   inc %ma. [ $+ [ $chan ] $+ .demoted_players_date. $+ [ %demoter ] $+ . $+ [ $replace($date,/,_) ] ]

      }
    }

    ; MISC 
    ;;;;;;;;;;;;;;;;
    else if ( $regex(%text,/^\* .*? was (slapped|high fived|kissed|hugged|tickled|punched|barfed on|brofisted|thrown|muted|insulted|beat down|murdered|got married to|madeout with) by .*$/) == 1 ) {
    }
    else {
      echo -s MA: Unknown action from $nick $+ : $1- 
    }
  }
}

alias ma.getnick {
  return $ma_getnick($1-)
}

alias -l ma_getnick {
  var %nick = $strip($1-)    

  if ($len(%nick) > 60) {
    %nick = $left(%nick,60)
  }

  %nick = $ma.StripNameTags(%nick)

  var %allowed = abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ _.@1234567890

  var %cur = $len(%nick)
  while (%cur > 0) {
    if ($mid(%nick,%cur,1) !isin %allowed) {
      %nick = $remove(%nick,$v1)
      %cur = $len(%nick)
    }
    else {
      dec %cur
    }
  }

  if ($len(%nick) <= 0) {

    var %nick = $strip($1-)    

    if ($len(%nick) > 60) {
      %nick = $left(%nick,60)
    }

    %nick = $ma.StripNameTags2(%nick)

    var %cur = $len(%nick)
    while (%cur > 0) {
      if ($mid(%nick,%cur,1) !isin %allowed) {
        %nick = $remove(%nick,$v1)
        %cur = $len(%nick)
      }
      else {
        dec %cur
      }
    }

    if ($len(%nick) <= 0) {

      ;echo -s Returning unknown nick: $1-
      return unknown

    }
  }

  ; For mcdienzzy server
  if ($gettok(%nick,1-3,32) == Lately known as || $gettok(%nick,2-3,32) == is AFK) {
    return unknown
  }

  if ($len(%nick) > 32) {
    %nick = $left(%nick,32)
  }

  return %nick
}

alias ma.StripNameTags {
  var %name = $1-
  var %tags = [] {} () <>
  var %i = 1

  while (%i <= $numtok(%tags,32)) {
    var %tag1 = \ $+ $left($gettok(%tags,%i,32),1)
    var %tag2 = \ $+ $right($gettok(%tags,%i,32),1)

    var %reg = /^.? $+ %tag1 $+ (.*) $+ %tag2 $+ (.*?)$/
    ;  echo -a reg1: %reg
    while ($regex(%name,%reg) ) {
      %name = $iif($regml(2) && $regml(2) != *,$v1,$regml(1))
      ; echo -s name1 %name %tag1
    }
    %reg = /^(.*?) $+ %tag1 $+ (.*) $+ %tag2 $+ $/
    ;    echo -a reg2: %reg
    while ($regex(%name,%reg)) {
      %name = $regml(1)
      ;echo -s name2 %name %tag1
    }

    inc %i
  }
  return %name
}

alias ma.StripNameTags2 {
  var %name = $1-
  var %tags = [] {} () <>
  var %i = 1
  while (%i <= $numtok(%tags,32)) {
    var %tag1 = \ $+ $left($gettok(%tags,%i,32),1)
    var %tag2 = \ $+ $right($gettok(%tags,%i,32),1)

    var %reg = /^(.*?) $+ %tag1 $+ (.*) $+ %tag2 $+ (.*?)$/
    while ( $regex(%name,%reg) ) {
      %name = $regml(2)
    }

    inc %i
  }
  return %name
}

alias -l ma_getrank {


  ; Ranks off - default to guest
  if (%ma. [ $+ [ $chan ] $+ .rank_set ] != 1) { 
    return $iif($3 == 1,-2,0)
  } 

  if ($left($1,1) == $chr(3) && $mid($1,2,2) isnum) {

    if ($right($strip($1),1) == $chr(42)) { return $iif($3 == 1,-2,0) } ; Freezed / Banned (default to guest)

    ; Nickname contains multiple words (/setinfo DisplayName)
    if ($numtok($1,32) > 1) {
      return $iif($3 == 1 || $3 == 2,-3,$calc(%ma. [ $+ [ $2 ] $+ .MultiColorValue ] ))
    }

    ; multicolor check
    var %end = 0
    if ($numtok($1,3) > 2 && $mid($1,-3,1) == $chr(3) && $mid($1,-2,2) isnum) {
      %end = 1
    }  
    if ($calc($numtok($1,3) - %end) > 2) {
      ;echo -s chan: $chan nick: $1 rank: $calc(%ma. [ $+ [ $2 ] $+ .MultiColorValue ] )
      return $iif($3 == 1 || $3 == 2,-2,$calc(%ma. [ $+ [ $2 ] $+ .MultiColorValue ] ))
    }

    var %color = $calc($mid($1,2,2))

    var %prefix = $left($strip($1),1)
    var %tags = [({<
    if (%prefix isalnum || %prefix == _  || %setprefix == $chr(46) || %setprefix == @ || %prefix isin %tags) {
      %prefix = $null
    }

    if (%prefix == $chr(40) && $gettok($strip($1),1,32) == $chr(40) $+ console $+ $chr(41)) {
      return $ma.getHighestRankValue($chan)
    }

    var %i = 1
    while (%i <= $var(%ma. [ $+ [ $2 ] $+ .RankSetting.* ] ,0)) {
      var %set = $var(%ma. [ $+ [ $2 ] $+ .RankSetting.* ] ,%i).value
      if (%set) {
        var %setprefix = $gettok(%set,3,32)
        if (%setprefix isalnum || %setprefix == _ || %setprefix == $chr(46) || %setprefix == @ || %setprefix isin %tags) {
          %setprefix = $null
        }
        if ($gettok(%set,2,32) == %color && %setprefix == %prefix) {
          if ($3 == 1) {
            return %color %prefix
          }
          else if ($3 == 2) {
            return $var(%ma. [ $+ [ $2 ] $+ .RankSetting.* ] ,$calc(%i + 1)).value
          }
          ;echo -s chan: $chan nick: $1 rank: $calc($gettok(%set,1,32))
          return $calc($gettok(%set,1,32))
        }
      }
      inc %i
    }

    ; Edited nickname
    var %cur = $len($1)
    while (%cur > 0) {
      if ($mid(%nick,%cur,1) !isalnum && $mid(%nick,%cur,1) != _ && $mid(%nick,%cur,1) != $chr(46) && $mid(%nick,%cur,1) != @) {
        return $iif($3 == 1 || $3 == 2,-2,$calc(%ma. [ $+ [ $2 ] $+ .MultiColorValue ] ))
      }
      dec %cur
    }

    if (%ma.DB) {
      echo -s Unknown rank color: %color prefix: %prefix line: $1-
      var %servid = $ma.getServID($chan)
      var %nickname = $gettok($strip($1),1,32)
      %color = $ma.idToColor(%color)
      var %sql = INSERT into RankErrors (Server,prefix,color,nickname) VALUES ( %servid , $mysql_qt($mysql_real_escape_string(%ma.DB,%prefix)) , $mysql_qt($mysql_real_escape_string(%ma.DB,%color)) , $mysql_qt($mysql_real_escape_string(%ma.DB,%nickname)) )
      if (!$mysql_exec(%ma.DB,%sql)) {
        %sql = Update RankErrors set Nickname = $mysql_qt($mysql_real_escape_string(%ma.DB,%nickname)) where server= %servid and prefix = $mysql_qt($mysql_real_escape_string(%ma.DB,%prefix)) and color = $mysql_qt($mysql_real_escape_string(%ma.DB,%color))
        mysql_exec %ma.DB %sql
      }

    }

  }
  return $iif($3 == 1,-2,0)
}

alias -l ma.setOnline {
  if ($0 >= 4) {

    ;echo -s online thing: $1-
    var %sql = select playername from online where playername = $mysql_qt($mysql_real_escape_string(%ma.DB,$4-)) and server = $ma.getservid($1)
    if ($ma.getDBline(%sql) == $4-) {
      ; echo -s online update: $1-
      mysql_exec %ma.DB UPDATE online set Ranking = $3 , timestamp = now() where playername = $mysql_qt($mysql_real_escape_string(%ma.DB,$4-)) and server = $ma.getservid($1))
    }
    ;else if ($2 == 1 || $3 < %ma. [ $+ [ $1 ] $+ .hidesilent ] ) {
    else {
      ;echo -s online insert: $1-
      mysql_exec %ma.DB INSERT into online (server, playername, ranking) values ( $ma.getservid($1) , $mysql_qt($mysql_real_escape_string(%ma.DB,$4-)) , $3 )
    }
  }
}

; --------------------------------
; Timer that checks if temporarely allowed users on IRC are still there
; --------------------------------
alias -l ma.allowedCheck {
  var %id = 1
  while (%id <= $numtok(%ma. [ $+ [ $chan ] $+ .allowed ] ,32)) {
    if ($gettok(%ma. [ $+ [ $chan ] $+ .allowed ] ,%id,32) !isreg $1) {
      set -e %ma. [ $+ [ $chan ] $+ .allowed ] $deltok(%ma. [ $+ [ $chan ] $+ ] .allowed,%id,32)
    }
    else {
      inc %id
    }
  }
  if ( $numtok(%ma. [ $+ [ $chan ] $+ .allowed ] ,32) == 0) {
    .timerma. [ $+ [ $chan ] $+ .allowedCheck ] off
  }
}

; --------------------------------
; Hackinform/Blacklist check for SMP Servers
; --------------------------------
on *:TEXT:*:#*.SMP:{ ma.SMPmatch $1- }
on *:TEXT:*:#*.CMP:{ ma.SMPmatch $1- }
on *:TEXT:*:#tekkitized:{ ma.SMPmatch $1- }

alias -l ma.SMPmatch {
  if ($nick && $chan) {
    var %smpnicks = CMB SVB SVB2 SMB SBC NyanServ BHSMP BHSMP2 TCI_Tekkit BOT
    if (!%ma. [ $+ [ $chan ] $+ .mute ] && $istok(%smpnicks,$nick,32)) {
      var %text = $strip($1-)

      var %nick = 0
      if ($numtok(%text,32) == 2 && $left(%text,1) == $chr(91) && $right(%text,1) == $chr(93) && $left($gettok(%text,2,32),-1) == connected) {
        %nick = $right($gettok(%text,1,32),-1)
      }
      else if ($numtok(%text,32) == 3 && $gettok(%text,1,32) == * && $gettok(%text,3,32) == connected.) {
        %nick = $gettok(%text,2,32)
      }

      if (%nick != 0) {

        %nick = $ma_getnick(%nick)
        if ((!%nick) || (%nick == unknown)) {
          echo -s nick error smp: $timestamp $chan $1-
          return
        }
        ;noop $ma.init_hackcheck($chan,%nick)

        if ($ma.getDBline(SELECT Name from Blacklist WHERE Name = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick)) ) == %nick && !%ma. [ $+ [ $chan ] $+ .spam ] ) {
          echo -s blacklist warn on $chan for %nick
          set -eu1 %ma. [ $+ [ $2 ] $+ .spam ] 1
          ma.msg $chan %nick might be associated with grief group iCanHasGrief.

        }

      }
    }
  }
}

; --------------------------------
; Hackinform for 800Craft Global Chat
; --------------------------------
on *:TEXT:*has enabled the Global Chat (Joined):#800craft:{
  if ((!%ma. [ $+ [ $chan ] $+ .mute ] ) && $numtok($1-,32) == 7 && $left($nick,1) == $chr(91)) {

    var %nick = $ma_getnick($gettok($strip($1-),1,32)) 
    if ((!%nick) || (%nick == unknown)) {
      return
    }

    if ( !%ma.#800Craft.recentlyOn. [ $+ [ %nick ] ] ) {

      noop $ma.init_hackcheck($chan,%nick)

      if ($ma.getDBline(SELECT Name from Blacklist WHERE Name = $mysql_qt($mysql_real_escape_string(%ma.DB,%nick)) ) == %nick && !%ma. [ $+ [ $chan ] $+ .spam ] ) {
        echo -s blacklist warn on $chan for %nick
        set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1
        ma.msg $chan %nick might be associated with grief group iCanHasGrief.       
      }
    }
    set -eu3600 %ma.#800Craft.recentlyOn. [ $+ [ %nick ] ] 1

  }

}

alias ma_mute { 
  if ($istok(%ma.servers,$chan,32)) { set %ma. [ $+ [ $chan ] $+ .mute ] 1 } 
  else { echo -a This is not a Minecraft server channel }
}
alias ma_unmute { 
  if ($istok(%ma.servers,$chan,32)) { unset %ma. [ $+ [ $chan ] $+ .mute ] } 
  else { echo -a This is not a Minecraft server channel }
}

; --------------------------------
; Website Password reset
; --------------------------------
on 1:TEXT:!passreset *:?:{
  if ($0 == 2 && $me ison $2 && $nick isop $2 && $istok(%ma.servers,$2,32) && $2 != #fcraft.server) {
    var %ret = $ma.passreset($2)
    if ($gettok(%ret,1,32) == Error:) {
      echo -s $timestamp Website password reset Failed for $2 by $nick
    }
    else {
      echo -s $timestamp Website password reset for $2 by $nick
    }
    msg $nick %ret
  }
  else {
    echo -s Failed passreset: $nick $1-
  }
  close -m $nick
}

; --------------------------------
; New Server Request
; --------------------------------
on 1:TEXT:!request *:?:{
  if (!%ma.newserver && $0 == 3 && $left($2,1) == $chr(35) && !$istok(%ma.servers,$2,32) && $me !ison $2  && $me != $3) {
    set -eu60 %ma.newserver 1 $nick $2 $3
    echo -s $timestamp $nick requesting new MC server.
    whois $nick
  }
}

raw 319:*: {
  if ($gettok(%ma.newserver,1,32) == 1 && $gettok(%ma.newserver,2,32) == $2) {
    if ($istok($3-,@ $+ $gettok(%ma.newserver,3,32),32)) {
      set -eu60 %ma.newserver 2 $gettok(%ma.newserver,2-,32)
      join $gettok(%ma.newserver,3,32)
    }
    else {
      set -eu60 %ma.newserver -1 $gettok(%ma.newserver,2-,32)
      msg $2 You aren't an operator of $gettok(%ma.newserver,3,32)
    }
  }
}

; --------------------------------
; Message replying
; --------------------------------
on *:TEXT:*:#:{

  if (!$istok(%ma.servers,$chan,32)) { 
    return
  }

  var %text = $strip($1-)

  if (%ma. [ $+ [ $chan ] $+ .mute ] ) {
    if (%text == !unmute && $nick isop $chan && !$ma.is_servbot($nick,$chan)) {
      echo -s $timestamp MA enabled at $chan by $nick
      unset %ma. [ $+ [ $chan ] $+ .mute ]
      if (%ma.DB) {
        mysql_exec %ma.DB UPDATE SERVERS set Muted = 0 where id = $ma.getServID($chan)
      }
      return 
    }
  }
  else {
    if (%text == !mute && $nick isop $chan && !$ma.is_servbot($nick,$chan)) {
      echo -s $timestamp MA disabled at $chan by $nick
      set %ma. [ $+ [ $chan ] $+ .mute ] 1
      if (%ma.DB) {
        mysql_exec %ma.DB UPDATE SERVERS set Muted = 1 where id = $ma.getServID($chan)
      }
      return
    }
    if (!%ma. [ $+ [ $chan ] $+ .disableplayers ] && !%ma. [ $+ [ $chan ] $+ .spam ] && (%text == .players || %text == !players) && !$ma.is_servbot($nick,$chan) ) {

      ;var %excludedchans = #shad4w
      ;if ($istok(%excludedchans,$chan,32)) {
      ;  return
      ;}

      set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1

      var %highranks = 0
      var %allranks = 0
      var %onlinelist = $null

      ; April fools
      if ($gettok($date,1-2,47) == 01/04) {
        var %r_p = $rand(1,2)
        if (%r_p == 1) {
          %onlinelist = Notch
        }
        else if (%r_p == 2) {
          %onlinelist = Honeydew 
        } 
        inc %allranks
      }

      var %sql = SELECT PlayerName, Ranking from Online where Server = $ma.getServID($chan) and (timestamp + INTERVAL 90 MINUTE) >= now() 
      var %res = $mysql_query(%ma.DB, %sql)
      if (%res) {
        while ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
          var %pname = $hget(row, PlayerName)
          var %prank = $hget(row, Ranking)
          %onlinelist = $addtok(%onlinelist,%pname,32)

          if (%prank >=  %ma. [ $+ [ $chan ] $+ .LowPromoRank ] ) {
            inc %highranks
          }
          inc %allranks
        }
        mysql_free %res
      }

      if (%allranks <= 20) {
        ma.msg $chan %allranks players online: %onlinelist ( %highranks visible moderators )
      }
      else {
        ma.msg $chan %allranks players online ( %highranks visible moderators )
      }
    }
  }

  ; Impersonation check

  if (%ma. [ $+ [ $chan ] $+ .impersonation ] == 1 && !%ma. [ $+ [ $chan ] $+ .mute ]  && $ma.is_servbot($nick,$chan) && !%ma. [ $+ [ $chan ] $+ .spam ] ) {
    var %irc = (IRC)
    if ($gettok(%text,1,32) == %irc && ($right($gettok(%text,2,32),1) == : || $gettok(%text,1,32) == $me $+ :)) {
      set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1
      if (($gettok(%text,1-2,32) == %irc $me) || ($gettok(%text,1-2,32) == %irc $me $+ :) || ($gettok(%text,1,32) == $me $+ :)) { 
        ma.msg $chan That wasn't me O_o    
      }
      else {
        ma.msg $chan That wasn't real $gettok(%text,2,32) 
      }
      return
    }
  }

  ; Checks if there are 2 similiar nicks on IRC channel and warns if there are (possible impersonation)
  ; Users may be temporarily allowed to have similiar nicks by giving them voice or typing !allow <nick> (requires voice or op status)
  if (%ma. [ $+ [ $chan ] $+ .impersonation ] == 1 && !%ma. [ $+ [ $chan ] $+ .mute ] && !$ma.is_servbot($nick,$chan) && (!%ma. [ $+ [ $chan ] $+ .spam ] ) && ($nick !isop $chan && $nick !isvoice $chan && !$istok(%ma. [ $+ [ $chan ] $+ .allowed ] ,$nick,32))  ) {

    var %leastdifs
    var %leastdifsnick
    var %differences
    var %pos
    var %nickpos = 1
    var %shortlen


    while (%nickpos <= $nick($chan,0,ohv)) {
      var %nick = $nick($chan,%nickpos,ohv)

      var %lendif = $abs($calc($len(%nick) - $len($nick)))
      %differences = %lendif

      if ($len(%nick) > $len($nick)) {
        %shortlen = $len($nick)
      }
      else {
        %shortlen = $len(%nick)
      }

      %pos = 1
      while (%pos <= %shortlen) {
        if ($mid($nick,%pos,1) != $mid(%nick,%pos,1)) {
          inc %differences
        }
        inc %pos
      }     

      var %mindif = 3
      if ($len(%nick) <= 6) {
        %mindif = 2
      }
      if ($len(%nick) <= 4) {
        %mindif = 1
      }

      if (%differences <= %mindif && $calc(%differences / (%lendif + %shortlen)  * 100) < 34  && (!%leastdifs || %differences < %leastdifs)) {
        %leastdifs = %differences
        %leastdifsnick = %nick
      }   

      inc %nickpos

    }

    if (%leastdifs) {

      if (!%ma. [ $+ [ $chan ] $+ .impersonation. $+ [ $nick ] ] ) {

        var %pair_p = $nick($chan,%leastdifsnick).pnick
        var %pair = $right(%pair_p,-1)
        var %addr = $gettok($address($nick,2),2,$asc(@))
        var %pair_addr = $gettok($address(%pair,2),2,$asc(@))

        if (%addr && %pair_addr && %addr != %pair_addr) {    
          set -eu45 %ma. [ $+ [ $chan ] $+ .impersonation. $+ [ $nick ] ] 1
          set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1
          ma.msg $chan Random user $nick has similiar nick to %pair_p $+ . Possible impersonation? IRC op or voiced person may allow him by voicing him or typing !allow $nick
        }
        else if (!%addr || !%pair_addr) {
          if (!%ma.DNS. [ $+ [ $nick ] ] && !%ma.DNS. [ $+ [ %pair ] ] ) {
            set -eu10 %ma.DNS. [ $+ [ $nick ] ] %pair_p $chan %addr
            set -eu10 %ma.DNS. [ $+ [ %pair ] ] $nick $chan %pair_addr   

            if (!%addr) {
              dns $nick
            }
            if (!%pair_addr) {
              dns %pair
            }
          }
        }

      }
    }
  }
  if ($1 == !allow && $2- isreg $chan && ($nick isop $chan || $nick ishop $chan || $nick isvoice $chan)) {
    set -e %ma. [ $+ [ $chan ] $+ .allowed ] $addtok(%ma. [ $+ [ $chan ] $+ .allowed ] ,$2,32)
    if ($numtok(%ma. [ $+ [ $chan ] $+ .allowed ] ,32) == 1) {
      .timerma. [ $+ [ $chan ] $+ .allowedCheck ] 0 30 ma.allowedCheck $chan
    }
    return
  }

  ; General spam check and verify we are receiving messages in proper format (The format bots are using)
  if ((!%ma. [ $+ [ $chan ] $+ .spam ] ) && $ma.is_servbot($nick,$chan) && ($regex($strip($1-,bur),/^(?!Players online)(.*): .*$/) == 1) && $len($gettok(%text,1,32)) > 1) {

    noop $ma.DBDateCheck()

    var %nick_tmp = $regml(1)
    var %rank = $calc($ma_getrank(%nick_tmp,$chan))
    var %frozen = $iif($left($strip(%nick_tmp),1) == * && $left($gettok(%nick_tmp,-2,3),3) == 12*,1,0)
    var %nick = $ma_getnick($strip(%nick_tmp))

    ;echo -s $timestamp $chan %nick is rank %rank

    if (%nick == unknown) {
      ; echo -s NICK ERROR main: $timestamp $chan $1-
    }
    else {
      noop $ma.setOnline($chan,0,%rank,%nick)
    }

    %text = $gettok(%text,$calc(1 + $numtok(%nick,32)) $+ -,32)

    if ($len(%text) > 2 && !%ma. [ $+ [ $chan ] $+ .multilang ] ) {
      set -eu60 $+(%,ma.,$chan,.lastline.,$replace(%nick,$chr(32),$chr(44))) %text
    }

    if (%rank >= $calc(%ma. [ $+ [ $chan ] $+ .LowMuteRank ] )) {

      if (%text == !mute) { 
        echo -s $timestamp MA disabled at $chan by %nick
        set %ma. [ $+ [ $chan ] $+ .mute ] 1 
        if (%ma.DB) {
          mysql_exec %ma.DB UPDATE Servers set Muted = 1 where id = $ma.getServID($chan)
        }
        return
      }
      else if (%text == !unmute) { 
        echo -s $timestamp MA enabled at $chan by %nick
        unset %ma. [ $+ [ $chan ] $+ .mute ] 
        if (%ma.DB) {
          mysql_exec %ma.DB UPDATE Servers set Muted = 0 where id = $ma.getServID($chan)
        }
        return
      }
    }

    ; Player specific spam check
    if ((!%ma. [ $+ [ $chan ] $+ .mute ] ) && ((!%ma. [ $+ [ $chan ] $+ .spam. $+ [ $replace(%nick,$chr(32),$chr(44)) ] ] ) || (%ma. [ $+ [ $chan ] $+ .spam. $+ [ $replace(%nick,$chr(32),$chr(44)) ] ] <= 5 ) ) && $numtok(%text,32) <= 20) {

      ; NO CAPS check
      var %allcaps = 0
      var %repnick = $replace(%nick,$chr(32),$chr(44))
      if (%text isupper && $len(%text) > 3 && $regex(%text,[A-Z]) >= 1 && %rank < $calc(%ma. [ $+ [ $chan ] $+ .LowPromoRank ] ) ) {     

        var %tmp_text = %text

        ; TODO: Pelaajien nimiä ei lasketa suuriksi kirjaimiski

        if (%tmp_text == %text || (%tmp_text isupper && $len(%tmp_text) > 3 && $regex(%tmp_text,[A-Z]) >= 1 && %rank < $calc(%ma. [ $+ [ $chan ] $+ .LowPromoRank ] ) ) ) {

          %allcaps = 1
          if ($regex_w(%text,(stop|help|gr(ei|ie)f(er|ing)?|destroying)) == 0) {

            if (%ma. [ $+ [ $chan ] $+ .CAPS. $+ [ %repnick ] ] > 3) {
              unset %ma. [ $+ [ $chan ] $+ .CAPS. $+ [ %repnick ] ] 
            }
            else if (%ma. [ $+ [ $chan ] $+ .CAPS. $+ [ %repnick ] ] >= 2) {
              set -eu120 %ma. [ $+ [ $chan ] $+ .CAPS. $+ [ %repnick ] ] $calc($v1 + 1)
              ma.msg $chan %nick $+ , Please turn off caps.


              set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1
              noop $ma.incPlayerSpam($chan,%nick,%rank)
              return
            }
            else {
              var %capsnum = %ma. [ $+ [ $chan ] $+ .CAPS. $+ [ %repnick ] ]
              set -eu150 %ma. [ $+ [ $chan ] $+ .CAPS. $+ [ %repnick ] ] $calc(%capsnum + 1)
            }
          }

        }      
      }

      if (%allcaps == 0) {
        unset %ma. [ $+ [ $chan ] $+ .CAPS. $+ [ %repnick ] ]
      }

      if (!$ma.is_ignored( %nick, $chan )) {

        ; Autoreplies start here
        ; -----------------------------------------------------------------------------

        ; Detect if there are any frequently asked questions in input
        ; On succesful detection give reply, call "ma.spam" and return


        ; How to fly? - Regex match written by Hafnium
        if (%ma. [ $+ [ $chan ] $+ .howtofly ] && $regex($lower(%text),((how|what|is there|if i)\b.+\b(do|can|are|to|2|i|you|u|did|could)\b.+\b(fly|flying|float|floating|hover|hovering|defy gravity|no.+clip|noclip|(go|run|move|moving|going|running|walk|walking|jump|jumping)\b.+\b(fast|quickly|high|tall)|speed)\b|\b(need|want|wanna|wana)\b.+\b(fly|flying|float|floating|hover|hovering|defy gravity|no.+clip|noclip|(go|going|run|running|move|moving|walk|walking|jump|jumping)\b.+\b(fast|quickly|high|tall)|speed)\b)) > 0 ) {
          if (tinyurl !isin %text && is.gd !isin %text && $regex_w(%text,(water|over|off|out|up|house|castle|build|a|an|the|there)) == 0) {
            if ((!$istok(%text,/fly,32) && !$istok(%text,fly/,32)) || (/fly !isin %ma. [ $+ [ $chan ] $+ .howtofly ] )) {
              ma.msg $chan %nick $+ , %ma. [ $+ [ $chan ] $+ .howtofly ]
              noop $ma.spam(%nick, $chan, %rank)
              return
            }
          }
        }

        if (($istok(%text,/fly,32) || $istok(%text,fly/,32)) && (!$istok(%ma. [ $+ [ $chan ] $+ .howtofly ] , /fly,32) && !$istok(%ma. [ $+ [ $chan ] $+ .howtofly ] , fly/,32)) ) {
          if (%ma. [ $+ [ $chan ] $+ .howtofly ] ) {
            ma.msg $chan %nick $+ , No /fly command here. %ma. [ $+ [ $chan ] $+ .howtofly ]
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
        }

        if ( ($regex_w(%text,(hax|h4x|hack|hacks|wom)) || (world of minecraft isin %text)) && $regex_w(%text,(how|where|link|url|(web)?site)) && $regex_w(%text,(get|dl|download)) ) {
          if (%ma. [ $+ [ $chan ] $+ .howtofly ] ) {
            if ( !$istok(%ma. [ $+ [ $chan ] $+ .howtofly ] , /fly,32) ) {
              ma.msg $chan %nick $+ , %ma. [ $+ [ $chan ] $+ .howtofly ]     
            }
            else {
              var %sites = $wildtok(%ma. [ $+ [ $chan ] $+ .howtofly ] ,*.*,0,32)
              if (%sites == 1) {
                ma.msg $chan %nick $+ , Get a client from: $wildtok(%ma. [ $+ [ $chan ] $+ .howtofly ] ,*.*,1,32)
              }
              else {
                ma.msg $chan %nick $+ , %ma. [ $+ [ $chan ] $+ .howtofly ]   
              }
            }     
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
        }

        if ( $regex_w(%text,(server(s)?|serveur(s)?)) && $regex_w(%text,(name|namn|call|called|calld)) && $regex_w(%text,(your|other)) == 0 && $numtok(%text,32) <= 10) {
          if (%ma. [ $+ [ $chan ] $+ .name ] && $regex_w(%text,(smp|survival|irc)) == 0) {
            var %i = 1
            var %ok = 1
            while (%i <= $numtok(%text,32)) {
              var %word = $gettok(%text,%i,32)
              if ($len(%word) > 4 && %word isin %ma. [ $+ [ $chan ] $+ .name ] ) {
                %ok = 0
              }
              inc %i
            }
            if (%ok == 1) {
              ma.msg $chan %nick $+ , Server name is: %ma. [ $+ [ $chan ] $+ .name ]
              noop $ma.spam(%nick, $chan, %rank)
              return
            }
          }
        }

        if ( ($istok(%text,where,32) || $regex_w(%text,(servers?|serveurs?)) && ($istok_whats(%text) || $regex_w(%text,(have|is))) || (how isin %text && get to isin %text) ) && $regex_w(%text,(site|website|url|page|webpage|forum(s)?|homepage)) && $regex_w(%text,(your|other)) == 0) {
          if (%ma. [ $+ [ $chan ] $+ .website ] && color !isin %text) {
            var %i = 1
            var %ok = 1
            while (%i <= $numtok(%text,32)) {
              var %word = $gettok(%text,%i,32)
              if ($len(%word) > 4 && $chr(46) isin %word && %word isin %ma. [ $+ [ $chan ] $+ .website ] ) {
                %ok = 0
              }
              inc %i
            }
            if (%ok == 1) {
              ma.msg $chan %nick $+ , Server website: %ma. [ $+ [ $chan ] $+ .website ]
              noop $ma.spam(%nick, $chan, %rank) 
              return
            }
          }
        }

        if ( $regex_w(%text,how) && $regex_w(%text,(join|go|change|switch)) && $regex_w(%text,(map(s)?|map|world(s)?|level(s)?|lvl(s)?|area(s)?)) && $regex_w(%text,(promo(te|ted)?|up)) == 0 && cant !isin %text && can't !isin %text && color !isin %text) {
          if (own !isin %text) {
            ma.msg $chan %nick $+ , Type /worlds to see map list. /j MapName to go there.
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
          else if ($chan == #fcraft.server) {
            ma.msg $chan Donators can get their own maps.
          }
        }

        if (%ma. [ $+ [ $chan ] $+ .rank_set ] == 1) {

          var %askedrank = $istok_ranks(%text)
          if ($regex_w(%text,rank(s|d|ed)?) || promo isin %text || upgrade isin %text || ((level isin %text || lvl isin %text) && reset !isin %text && wipe !isin %text) || %askedrank) {
            if ($istok(%text,how,32) || (can i isin %text) || ($istok(%text,where,32) && $regex_w(%text,(apply|aplly)) ) || ($istok(%text,when,32) && ($istok(%text,will,32) || 'll isin %text ))) {

              if ($regex_w(%text,(see|c|look|check|watch|rate|(re)?view|come)) == 0) {
                if ($regex_w(%text,(help|as|world|map)) == 0 && ($chr(47) !isin %text)) {
                  if ($regex($lower(%text),/\b(to|for|4)\b \b(me|my|this) $+ [^0-9a-z_]*\b/) == 0) {
                    if ($regex_w(%text,(was|were|got|since|ago|at|with|being)) == 0) { 
                      if ($regex_w(%text,(made|built|ready|rdy|thing|grief|tele|call|who|bring|finish)) == 0) {
                        if ($regex_w(%text,(many|are|long|ask|love|speak|it\'s|its|use|realm|about|him|her|still)) == 0) {

                          if (back isin %text || old rank isin %text) {
                            if (%ma. [ $+ [ $chan ] $+ .website ] ) {
                              ma.msg $chan %nick $+ , if you were wrongfully demoted, you may appeal at $v1
                              noop $ma.spam(%nick, $chan, %rank)
                              return
                            }
                          }
                          else {

                            if (%askedrank) {
                              if (%askedrank >  $var(%ma. [ $+ [ $chan ] $+ .RankSetting.* ] ,0)) {
                                %askedrank = $v2
                              }
                              %askedrank = $var(%ma. [ $+ [ $chan ] $+ .RankSetting.* ] ,%askedrank).value 
                            }
                            else {
                              if (%rank < $calc(%ma. [ $+ [ $chan ] $+ .LowPromoRank ] )) {
                                %askedrank = $iif($ma_getrank($strip($left($1,-1),bur),$chan,2) >= 0,$v1,$null)
                              }
                            }

                            var %msg = $null
                            var %ok = $iif(%askedrank,1,0)

                            var %optitle = Op
                            if ($chan == #spa.minecraft && (%askedrank && $gettok(%askedrank,1,32) > 1)) {
                              %optitle = Op
                            }
                            else {
                              %optitle = $iif($ma.getLowOpTitle($chan),$v1,Op)
                            }

                            if (%askedrank) {
                              var %promotype = $gettok($gettok(%askedrank,-2,32),1,32)
                              var %value = $gettok(%askedrank,1,32)
                              var %title = $replace($gettok(%askedrank,-1,32),_,$chr(32))

                              if (%promotype == 0) {
                                if (%value >= $calc(%ma. [ $+ [ $chan ] $+ .LowPromoRank ] )) {
                                  %msg = %nick $+ , %optitle and higher are selected from the fitting players. Not asking for it helps.
                                }
                              }
                              else if (%promotype == 1) {                              
                                %msg = %nick $+ , Ask %optitle $+ $chr(43) to come check your building(s) for %title rank.
                              }
                              else if (%promotype == 2) {
                                %msg = %nick $+ , To get %title $+ , apply for the rank at $iif(%ma. [ $+ [ $chan ] $+ .website ] ,$v1,our website) $+ $iif(%value < $calc(%ma. [ $+ [ $chan ] $+ .LowPromoRank ] ), $chr(32) $+ and show your builds there , $null) $+ $chr(46)
                              }
                              else if (%promotype == 3) {
                                %msg = %nick $+ , %title promo is automatic. Just keep building and having fun.
                              }
                              else if (%promotype == 4) {
                                %msg = %nick $+ , Keep building and follow the rules, we'll be reviewing your stats for %title $+ $chr(46)
                              }
                              else if (%promotype == 5) {
                                %msg = %nick $+ , Donate at $iif(%ma. [ $+ [ $chan ] $+ .website ] ,$v1,our website) for %title rank.
                              }
                              else {
                                %ok = 0
                              }
                            }

                            if (%ok == 0) {
                              var %i = 2
                              var %lasttype = $null
                              var %lasttitles = $null
                              while (%i <= $var(%ma. [ $+ [ $chan ] $+ .RankSetting.* ] ,0)) {
                                var %set = $var(%ma. [ $+ [ $chan ] $+ .RankSetting.* ] ,%i).value

                                var %promotype = $calc($gettok($gettok(%set,-2,32),1,32))
                                var %title = $replace($gettok(%set,-1,32),_,$chr(32))

                                if (!%lasttype || %lasttype == %promotype) {
                                  %lasttype = %promotype
                                  if (%promotype > 0) {
                                    %lasttitles = $iif(%lasttitles,$v1 $+ /,$null) $+ %title
                                  }
                                }
                                else {            

                                  if (%lasttype == 1) {
                                    %msg = %msg For %lasttitles ask %optitle $+ $chr(43) to check buildings,
                                  }
                                  else if (%lasttype == 2) {
                                    %msg = %msg Apply at $iif(%ma. [ $+ [ $chan ] $+ .website ] ,$v1,our website) for %lasttitles $+ , 
                                  }
                                  else if (%lasttype == 3) {
                                    %msg = %msg %lasttitles promos are automatic,
                                  }
                                  else if (%lasttype == 4) {
                                    %msg = %msg We'll review stats for %lasttitles $+ ,
                                  }

                                  %lasttype = %promotype

                                  if (%promotype > 0) {
                                    %lasttitles = %title
                                  }
                                  else {
                                    %lasttitles = $null
                                  }
                                }
                                inc %i
                              } 
                              if ($right(%msg,1) == ,) { %msg = $left(%msg,-1) }
                            }

                            if (%msg) {
                              ma.msg $chan %msg
                              noop $ma.spam(%nick, $chan, %rank)
                              return
                            }
                          }

                        }
                      }             
                    }
                  }
                }
              }
            }
          }
        }

        if ($regex_w(%text,(chinese|bud(d)?hist(s)?|hind(u|i)(s)?|asian(s))) && $regex_w(%text,(sign|symbol|mark)) && $regex_w(%text,(peace|luck)) ) {

          ma.msg $chan %nick $+ , Swastikas are not allowed.
          noop $ma.spam(%nick, $chan, %rank)
          return
        }
        if (swasti isin %text && (can i isin %text) && remove !isin %text && del !isin %text && erase !isin %text && $chr(47) !isin %text) {

          ma.msg $chan %nick $+ , Swastikas are not allowed.
          noop $ma.spam(%nick, $chan, %rank)
          return
        }

        if ($regex_w(%text,sple(e)*f(ing)?) && ($regex_w(%text,mean(s)?) || $istok_whats(%text)) && $regex_w(%text,point|why|for|4|she|he) == 0) {
          ma.msg $chan Spleefing: Deleting blocks under a person.
          noop $ma.spam(%nick, $chan, %rank)
          return
        }

        if ($regex_w(%text,gr(ie|ei)f(ing)?) && ($regex_w(%text,mean(s)?) || $istok_whats(%text)) && $regex_w(%text,point|why|for|4|she|he) == 0) {
          if (speed isin %text) {
            ma.msg $chan Speedgrief: Destroying other peoples stuff using a speed hack such as WoM.
          }
          else {
            ma.msg $chan Griefing: Destroying other peoples stuff, random blocks, tunnels or holes.
          }
          noop $ma.spam(%nick, $chan, %rank)
          return     
        }

        if ($regex_w(%text,tunnel(s)?) && $chr(47) !isin %text && ((can isin %text && I isin %text) || (is isin %text && allowed isin %text && isn !isin %text && is not !isin %text))) {

          ma.msg $chan Tunnel with purpose. No random tunneling.
          noop $ma.spam(%nick, $chan, %rank)
          return
        }

        if ($regex_w(%text,(water|lava)) && !$istok(%text,high,32) && !$istok(%text,about,32) && out of !isin %text && !$istok(%text,ontop,32) && on top !isin %text && ($regex_w(%text,how) || (there isin %text && way isin %text)) && ($istok(%text,make,32) || $istok(%text,do,32) || $istok(%text,get,32)  || $istok(%text,add,32) || $istok(%text,put,32) || $istok(%text,create,32) || $istok(%text,use,32) || $istok(%text,place,32) || $istok(%text,build,32)) ) {

          if (go away isin %text || take away isin %text || $regex_w(%text,(rid|delete|remove|destroy|erase)) ) {
            ma.msg $chan %nick $+ , just place a block on top the water/lava
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
          else { 
            var %waterrank = $iif( $calc(%ma. [ $+ [ $chan ] $+ .LowWaterRank ] ) >= 0,$calc($v1 + 1), 2)
            var %title = $replace($gettok(%ma. [ $+ [ $chan ] $+ .RankSetting. $+ [ %waterrank ] ] ,-1,32),_,$chr(32))
            var %color = $ma.idToColor($gettok(%ma. [ $+ [ $chan ] $+ .RankSetting. $+ [ %waterrank ] ] ,2,32))
            ;echo -s $timestamp $chan %nick rank: %rank waterrank: %waterrank
            if (%title && %color) {  
              if ($calc(%rank + 1) < %waterrank) {             
                ma.msg $chan %nick $+ , ask a %title ( $+ %color name) to make some water/lava for you.
              }
              else {         
                ma.msg $chan %nick $+ , Type /water or /lava and then place blue/red blocks.
              }
              noop $ma.spam(%nick, $chan, %rank)
              return
            }
          }
        }

        if ($regex_w(%text,(tnt(s)?|dynamite(s)?|explosive(s)?)) && ($regex_w(%text,(how|why|can|does)) || ($istok(%text,is,32) && $istok(%text,way,32))) && $regex_w(%text,(blow|set off|go off|explode|boo+m|activate|detonate|work|ignite|use|light))) {
          ma.msg $chan %nick $+ , you can't blow the tnt in classic mode.
          noop $ma.spam(%nick, $chan, %rank)
          return
        }

        if ($regex_w(%text,grass) && $regex_w(%text,(how|grow)) && cut !isin %text && /grass !isin %text) {

          ma.msg $chan %nick $+ , Type /grass and place ground blocks.
          noop $ma.spam(%nick, $chan, %rank)
          return
        }

        if (($istok_cant(%text) && $istok(%text,get,32) && $regex_w(%text,(out|back)) ) || ($regex_w(%text,(stuck|trapped)) && ($istok_im(%text) || i got isin %text)) || ($istok(%text,help,32) && $istok(%text,lost,32) ) && sleep !isin %text && that !isin %text && !$istok(%text,it,32) && !$istok(%text,as,32)) {
          if (head !isin %text) {

            if (%frozen) {
              ma.msg $chan %nick $+ , You are frozen because of suspected rule breaking
            }
            else {
              ma.msg $chan %nick $+ , Press R to get back to last saved point (ENTER to save current location) or type /spawn to go to start.
            }
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
        }
        if ($regex_w(%text,how) && ($istok(%text,/c,32) || (to cuboid isin %text) || (use cuboid isin %text)) && school !isin %text) {
          if ($chan == #fcraft.server) {
            ma.msg $chan %nick $+ , To learn /c, Type /j school
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
        }

        if (what isin %text && rules isin %text && ($chr(47) $+ rules !isin %text) && $numtok(%text,32) <= 6) {

          ma.msg $chan %nick $+ , Type /rules
          noop $ma.spam(%nick, $chan, %rank)
          return
        }

        if ($regex_w(%text,how) && ($regex_w(%text,(whisper|pm)) || (privat isin %text && $regex_w(%text,(chat|talk|speak|msg(s)?|message(s)?)) ) )) {
          ma.msg $chan %nick $+ , Type: @playername infront of your message to chat privately
          noop $ma.spam(%nick, $chan, %rank)
          return
        }

        if ((reset isin %text || wipe isin %text || restart isin %text) && (main isin %text || map isin %text || world isin %text || server isin %text) && ($istok(%text,when,32) || $istok(%text,does,32) || do you isin %text) && !$istok(%text,we,32) && $numtok(%text,32) <= 8) {

          if ($chan == #fcraft.server) {
            ma.msg $chan Main world is reset 1-2 times a day. Other worlds stay.
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
          else if ($chan == #spa.minecraft) {
            ma.msg $chan Main world is reset when it's full. Other worlds stay.
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
        }

        if ($regex_w(%text,how) && $regex_w(%text,(other|different|change|switch)) && block isin %text) {
          ma.msg $chan %nick $+ , Press B to make other blocks.
          noop $ma.spam(%nick, $chan, %rank)
          return
        }

        if ($me isin %text && say !isin %text && $regex_w(%text,(check|view|review|see|look|watch|promo(te)?|rank)) && $regex_w(%text,(buil(t|d|ding|dings|ds)|house(s)?|castle|this|me|my)) ) {

          ma.msg $chan %nick $+ , Human reviewing and judgement modules are far better than mine, you should ask one of the ops instead.
          noop $ma.spam(%nick, $chan, %rank)
          return
        }

        if (((demote isin %text || unpromote isin %text) && undemote !isin %text && $istok(%text,i,32) && ($istok(%text,got,32) || $istok(%text,was,32)) && him !isin %text && her !isin %text) || ( $regex_w(%text,how) && $regex_w(%text,appeal) &&  $regex_w(%text,(long|once)) == 0)) {
          if (%ma. [ $+ [ $chan ] $+ .website ] ) {
            ma.msg $chan %nick $+ , if you were wrongfully demoted, you may appeal at %ma. [ $+ [ $chan ] $+ .website ]
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
        }


        if (($istok_whats(%text) || (what isin %text && ($regex_w(%text,mean(s)?) || stand for isin %text) )) && $regex_w(%text,irc) && $regex_w(%text,(link|url|site|website|colo(u)?r(s)?|name(s)?)) == 0 && got to do !isin %text) {
          if ($regex_w(%text,(channel|chan|address|where))) {
            ma.msg $chan %nick $+ , Our IRC channel is $chan @ $network
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
          else {
            ma.msg $chan %nick $+ , IRC = Internet Relay Chat. People on IRC can chat, but not interact with the game.
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
        }

        ; Sing-along Themesongs ( My Little Pony, Pokemon, etc )
        if (%ma. [ $+ [ $chan ] $+ .themes_set ] == 1 ) {
          var %i = $numtok(%themesongs.loaded,32)
          while (%i > 0) {

            var %theme = $gettok(%themesongs.loaded,%i,32)
            if ($isthemesong(%theme,%text)) {

              var %lastthemeline = $v1
              if (!%ma. [ $+ [ $chan ] $+ .lasttheme. $+ [ %theme ] ] || %lastthemeline != %ma. [ $+ [ $chan ] $+ .lasttheme. $+ [ %theme ] ] ) {
                set -eu60 %ma. [ $+ [ $chan ] $+ .lasttheme. $+ [ %theme ] ] %lastthemeline

                ma.msg $chan %lastthemeline

                set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1
                noop $ma.incPlayerSpam($chan,%nick,%rank,0.5)
              }
              return
            }
            dec %i
          }
        }

        ; Custom Rules
        ; ------------
        if (%ma. [ $+ [ $chan ] $+ .CustomRule.M.1 ] ) {
          ;var %clock = $uptime(mirc,1)
          var %i = 1
          while (%ma. [ $+ [ $chan ] $+ .CustomRule.M. $+ [ %i ] ] ) {
            ; var %regexp = %ma. [ $+ [ $chan ] $+ .CustomRule.M. $+ [ %i ] ]
            if ($regex(%text, %ma. [ $+ [ $chan ] $+ .CustomRule.M. $+ [ %i ] ] ) > 0) {
              ;echo -s $chan %text :matched: %regexp
              var %reply = %ma. [ $+ [ $chan ] $+ .CustomRule.R. $+ [ %i ] ]
              %reply = $replace(%reply, $chr(36) $+ nick, %nick)

              var %checkrank = 1
              if (%rank > 0) {
                %checkrank = $calc(%rank +1) 
              }
              var %rankname = $replace($gettok(%ma. [ $+ [ $chan ] $+ .RankSetting. $+ [ %checkrank ] ] ,-1,32),_,$chr(32))
              var %nextrankname = $replace($gettok(%ma. [ $+ [ $chan ] $+ .RankSetting. $+ [ $calc(%checkrank + 1) ] ] ,-1,32),_,$chr(32))

              if ($len(%nextrankname) == 0) {
                %nextrankname = %rankname
              }

              %reply = $replace(%reply, $chr(36) $+ rank, %rankname)
              %reply = $replace(%reply, $chr(36) $+ nextrank, %nextrankname)

              if ($chr(36) $+ ircnames isin %reply) {
                var %i = $nick($chan,0)
                if (%i >= 20) {
                  %reply = $replace(%reply, $chr(36) $+ ircplayers, -Too many names ( $+ %i $+ )- )
                }
                else {
                  var %ircnames = $null
                  while (%i > 0) {
                    if ($nick($chan,%i) != $me) {
                      %ircnames = $addtok(%ircnames,$nick($chan,%i),32)
                    }
                    dec %i
                  }
                  %reply = $replace(%reply, $chr(36) $+ ircnames, %ircnames)
                }
              }

              if ($chr(36) $+ players isin %reply) {
                var %onlinelist = $null

                var %sql = SELECT PlayerName from Online where Server = $ma.getServID($chan) and (timestamp + INTERVAL 90 MINUTE) >= now() 
                var %res = $mysql_query(%ma.DB, %sql)
                if (%res) {
                  while ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
                    %onlinelist = $addtok(%onlinelist,$hget(row, PlayerName),32)
                  }
                  mysql_free %res
                }
                %reply = $replace(%reply, $chr(36) $+ players, %onlinelist)
              }

              if ($len(%reply) > 0) {
                msg $chan %reply
                noop $ma.spam(%nick, $chan, %rank)
              }
              return
            }
            inc %i
          }
          ;echo -s cr ticks $chan : $calc($uptime(mirc,1) - %clock)
        }

      }


      ; Auto replies end here
      ; ------------------------------------------------------------------------------


      if (%rank >= $calc(%ma. [ $+ [ $chan ] $+ .LowSpleefRank ] )) {     
        if (%text == !spleef && !$timer(ma.spleef. $+ $chan)) {
          set -eu5 %ma. [ $+ [ $chan ] $+ .spam ] 1
          set %ma.spleef. [ $+ [ $chan ] ] 0
          .timerma.spleef. $+ $chan 4 1 ma.spleef $chan 3
          return
        }
      }

      ; Limit these commands to Op+
      if (%rank >= $calc(%ma. [ $+ [ $chan ] $+ .LowPromoRank ] )) {

        if ($chan == #mcchawk) {

          ; !voice and !devoice for #mcchawk
          if ($gettok(%text,1,32) == !voice && $gettok(%text,2,32) ison $chan) {
            if ($me isop $chan && $gettok(%text,2,32) != $me && !$ma.is_servbot($gettok(%text,2,32),$chan) ) {
              mode $chan +v $gettok(%text,2,32)
            }
            return
          }
          else if ($gettok(%text,1,32) == !devoice && $gettok(%text,2,32) ison $chan) {
            if ($me isop $chan && $gettok(%text,2,32) != $me && !$ma.is_servbot($gettok(%text,2,32),$chan)) {
              mode $chan -v $gettok(%text,2,32)
            }
            return
          }

          if ($istok(%ma. [ $+ [ $chan ] $+ .botauth ] , $nick,32)) {

            if ($gettok(%text,1,32) == !kick && $gettok(%text,2,32) ison $chan) {
              if ($me isop $chan && $gettok(%text,2,32) != $me && !$ma.is_servbot($gettok(%text,2,32),$chan)) {
                kick $chan $gettok(%text,2,32)
              }
              return
            }
            else if ($gettok(%text,1,32) == !op && $gettok(%text,2,32) ison $chan) {
              if ($me isop $chan && $gettok(%text,2,32) != $me && !$ma.is_servbot($gettok(%text,2,32),$chan)) {
                mode $chan +o $gettok(%text,2,32)
              }
              return
            }
            else if ($gettok(%text,1,32) == !deop && $gettok(%text,2,32) ison $chan) {
              if ($me isop $chan && $gettok(%text,2,32) != $me && !$ma.is_servbot($gettok(%text,2,32),$chan)) {
                mode $chan -o $gettok(%text,2,32)
              }
              return
            }
          }
        }

        ; Checks if there are any players with kick count higher than 3
        ; and then gives the playername so they can be reviewed for banning

        if (any bans needed isin %text || !bans == %text ) {

          var %sql = select Name from Kicks where Server = $calc($ma.getservid($chan)) and Count >= 4
          var %res = $mysql_query(%ma.DB, %sql)
          var %names = $null
          if (%res) {         
            while ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
              %names = %names $hget(row, Name)
            }
            mysql_free %res
          }

          if (%names) {
            ma.msg $chan These players have been kicked many times: %names
          }
          else {
            ma.msg $chan No bans needed
          }
          noop $ma.spam(%nick, $chan, %rank)
          return
        }

        else if (%text == !fly) {
          if (%ma. [ $+ [ $chan ] $+ .howtofly ] ) {
            ma.msg $chan %nick $+ , %ma. [ $+ [ $chan ] $+ .howtofly ]
            noop $ma.spam(%nick, $chan, %rank)
            return
          }
        }

        ; !english - Google translated request for speaking english in chat
        else if (!%ma. [ $+ [ $chan ] $+ .multilang ] && !english == $gettok(%text,1,32) && $numtok(%text,32) >= 2 && $len($gettok(%text,2-,32)) <= 32) {
          var %targetnick = $gettok(%text,2-,32)
          var %targetnick_sr = $replace(%targetnick,$chr(32),$chr(44))
          var %matches = $var( $chr(37) $+ ma. $+ $chan $+ .lastline. $+ %targetnick_sr $+ *, 0 )

          if (%matches >= 1) {
            var %shortest = 1
            if (%matches > 1) {       
              var %length = $len($gettok($var( $chr(37) $+ ma. $+ $chan $+ .lastline. $+ %targetnick_sr $+ * ,1 ),-1,46))
              var %id = 2
              while (%id <= %matches ) {
                if ($len($gettok($var( $chr(37) $+ ma. $+ $chan $+ .lastline. $+ %targetnick_sr $+ * , %id ),-1,46)) < %length) {
                  %length = $v1
                  %shortest = %id
                }
                inc %id
              }

            }
            %targetnick_sr = $gettok($var( $chr(37) $+ ma. $+ $chan $+ .lastline. $+ %targetnick_sr $+ * , %shortest ),-1,46)
            %targetnick = $replace(%targetnick_sr,$chr(44),$chr(32))

            if (%targetnick_sr && %nick != %targetnick) {  

              ma.googletranslate $chan %targetnick_sr Auto $($+(%,ma.,$chan,.lastline.,%targetnick_sr),2)
              noop $ma.spam(%nick, $chan, %rank)
            }
            else if (%nick == %targetnick) {
              ma.msg $chan The %nick with split personality, tell the other you to speak in english. No wait... what?
            }
          }
          else {
            ma.msg $chan %targetnick hasn't said anything recently.    
          }
          return
        }

        else if (!promoratio == %text) {

          var %servid = $ma.getServID($chan)  
          var %opid
          if (%servid) {
            %opid = $ma.getOPID(%servid,%nick,1)
          }

          if (%servid && %opid) {

            var %sql = select LastAction, Promotes, Promobfires from Ops where id = %opid 
            var %res = $mysql_query(%ma.DB, %sql)
            if (%res) {

              if ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {

                var %lastact = $iif($hget(row, LastAction),$v1,$ctime)
                var %promos =  $iif($hget(row, Promotes),$v1,0)
                var %promobfire = $iif($hget(row, Promobfires),$v1,0)

                var %relevance = $calc(1 - (($ctime - $ctime(%lastact)) / 60 / 60 / 24 / 60))
                if (%relevance < 0 || %relevance > 1) {
                  %relevance = 0
                }

                var %naive_per_rel = $round($calc((%promobfire * %relevance) / %promos * 100 ),2)
                var %naive_per = $round($calc(%promobfire / %promos * 100 ),2) 

                ma.msg $chan %nick $+ , %promos players promoted of which %naive_per $+ $chr(37) ( $+ %promobfire $+ ) have been demoted or banned afterwards. $chr(37) used in calculations is %naive_per_rel $+ $chr(37)
              }
              mysql_free %res
            }
          }
        }

        ; Trustee+ !commands
        ;------------------
        if (%rank >= $calc(%ma. [ $+ [ $chan ] $+ .LowMuteRank ] )) {
          if (%text == !allow && $2- isreg $chan) {
            set -e %ma. [ $+ [ $chan ] $+ .allowed ] $addtok(%ma. [ $+ [ $chan ] $+ .allowed ] ,$2,32)
            if ($numtok(%ma. [ $+ [ $chan ] $+ .allowed ] ,32) == 1) {
              .timerma. [ $+ [ $chan ] $+ .allowedCheck ] 0 30 ma.allowedCheck $chan
            }
            return
          }
        }
      }

      if (%text == !ignoreme) {
        var %id = 1
        while ($numtok(%ma. [ $+ [ $chan ] $+ ] .ignored. [ $+ [ %id ] ] ,32) >= 175) {
          inc %id
        }
        set %ma. [ $+ [ $chan ] $+ ] .ignored. [ $+ [ %id ] ] $addtok(%ma. [ $+ [ $chan ] $+ ] .ignored. [ $+ [ %id ] ] ,$replace(%nick,$chr(32),$chr(44)),32)
      }

      else if (%text == !unignoreme) {
        var %max = $var(%ma. [ $+ [ $chan ] $+ ] .ignored.*,0)
        var %id = 1     
        while (%id <= %max) {
          set %ma. [ $+ [ $chan ] $+ ] .ignored. [ $+ [ %id ] ] $remtok(%ma. [ $+ [ $chan ] $+ ] .ignored. [ $+ [ %id ] ] ,$replace(%nick,$chr(32),$chr(44)),0,32)
          inc %id
        }  
      }

      ; The following is just to make the bot more lifelike
      ; Doesn't increase reply count

      ; Jokes
      else if (%ma. [ $+ [ $chan ] $+ .jokes_set ] == 1 && $me isin %text && joke isin %text && !$istok(%text,is,32) && !$istok(%text,not,32)) {

        ;var %excludedchans = #shad4w
        ;if ($istok(%excludedchans,$chan,32)) {
        ;  return
        ;}

        set -eu1 %ma. [ $+ [ $chan ] $+ ] .spam 1

        noop $ma.incPlayerSpam($chan,%nick,%rank)

        var %jokes = $lines($scriptdir $+ ma_jokes.txt)
        if (%jokes > 0) {
          var %retries = 0
          var %r = $rand(1,%jokes)
          while (%retries < 25 && $istok(%ma. [ $+ [ $chan ] $+ .lastjokes ] , %r,32)) {
            %r = $rand(1,%jokes)
            inc %retries
          }

          set %ma. [ $+ [ $chan ] $+ .lastjokes ] $addtok(%ma. [ $+ [ $chan ] $+ .lastjokes ] ,%r,32)
          if ($numtok(%ma. [ $+ [ $chan ] $+ .lastjokes ] ,32) > 10) {
            set %ma. [ $+ [ $chan ] $+ .lastjokes ] $deltok(%ma. [ $+ [ $chan ] $+ .lastjokes ] , 1 - $calc($v1 - 10),32)
          }

          ma.msg $chan $read($scriptdir $+ ma_jokes.txt,nt,%r)

        }
        else {
          ma.msg $chan Jokes file is empty or missing.
        }
      }

      ; Fun facts

      else if (%ma. [ $+ [ $chan ] $+ .funfact_set ] == 1  && $regex_w(%text,$me) && $regex_w(%text,(fact(s)?|funfact(s)?)) ) {   

        var %servid = $ma.getServID($chan)
        if (!%servid || !%ma.datefrm) {
          return
        }

        var %kicks 
        var %bans
        var %replies
        var %hackinforms
        var %visitors
        var %thanks
        var %queryok

        var %sql = select Kicks, Bans, Replies, Hackinforms, Visitors, Thanks FROM Servers where id = %servid
        var %res = $mysql_query(%ma.DB, %sql)
        if (%res) {
          if ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
            %queryok = 1
            %kicks = $hget(row, Kicks)
            %bans = $hget(row, Bans)
            %replies = $hget(row, Replies)
            %hackinforms = $hget(row, Hackinforms)
            %visitors = $hget(row, Visitors)
            %thanks =  $hget(row, Thanks)
          }
          mysql_free %res
        }

        if (!%queryok) {
          return
        }  

        set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1

        noop $ma.incPlayerSpam($chan,%nick,%rank)

        var %days = $round($calc(($ctime($date) - $ctime($ma.GetFirstDate($chan))) / 60 /60 / 24),0)
        var %date = $asctime($calc($ctime($date) - 86400), %ma.datefrm)  
        var %r = -1 

        if (%days < 1) {
          ma.msg $chan Stats recording hasn't been running long enough for fun facts.
          return
        }

        if ($findtok(%text,fact,1,32) > 0) {
          %r = $iif($gettok(%text,$calc($v1 + 1),32) isnum, $v1, -1)        
        }   
        if (%r == -1) {
          if ($findtok(%text,funfact,1,32)) {
            %r = $iif($gettok(%text,$calc($v1 + 1),32) isnum, $v1, -1)        
          }   
        }

        var %max = 11
        if (%r > %max) {
          %r = %max
        }

        if (%r < 1) {
          var %retries = 0
          %r = $rand(1,%max)
          while (%retries < 10 && $istok(%ma. [ $+ [ $chan ] $+ .lastfunfacts ] , %r,32)) {
            %r = $rand(1,%max)
            inc %retries
          }
        }

        var %remember = 6

        set %ma. [ $+ [ $chan ] $+ .lastfunfacts ] $addtok(%ma. [ $+ [ $chan ] $+ .lastfunfacts ] ,%r,32)
        if ($numtok(%ma. [ $+ [ $chan ] $+ .lastfunfacts ] ,32) > %remember) {
          set %ma. [ $+ [ $chan ] $+ .lastfunfacts ] $deltok(%ma. [ $+ [ $chan ] $+ .lastfunfacts ] , 1 - $calc($v1 - %remember),32)
        }

        if (%r == 1) {       
          var %percent = That's $round($calc(%kicks / %visitors * 100 ),2) $+ $chr(37) of our visitors.
          ma.msg $chan We kick an average of $round($calc(%kicks / %days),0) players daily. $iif(%visitors > 0,%percent)
        }
        else if (%r == 2) {
          var %percent = That's $round($calc( %bans / %visitors * 100 ),2) $+ $chr(37) of our visitors.
          ma.msg $chan We ban an average of $round($calc(%bans / %days),0) players daily. $iif(%visitors > 0,%percent)
        }
        else if (%r == 3) {       
          ma.msg $chan I answer $round($calc(%replies / %days),0) questions daily. So far I've answered to %replies questions
        }
        else if (%r == 4) {
          if ($calc(%hackinforms ) == 0) {
            ma.msg $chan 0 of our visitors is known to have had their account hacked by fake clients.
          }
          else {
            var %percent = That's 1 in every $round($calc(%visitors / %hackinforms ),0) visitor.
            ma.msg $chan %hackinforms of our visitors is known to have had their account hacked by fake clients. $iif(%visitors > 0,%percent)  
          }
        }
        else if (%r == 5) {
          ma.msg $chan %thanks people said thanks to me after getting an answer *sniff* Are you one of these kind $round($calc(%thanks / %replies * 100),2) $+ $chr(37) ?
        }
        else if (%r == 6) {
          var %ypromos = $ma.getDBline(select promotes from Stats where server = %servid AND date = $mysql_qt( $mysql_real_escape_string(%ma.DB,%date) ) ) 
          var %ydemos = $ma.getDBline(select demotes from Stats where server = %servid AND date = $mysql_qt( $mysql_real_escape_string(%ma.DB,%date) ) ) 
          ma.msg $chan Yesterday $calc(%ypromos) people were promoted and $calc(%ydemos) demoted.
        }
        else if (%r == 7) {

          var %sql = select * from ( $&
            select name, promotes, promobfires, (promobfires*relevance/promotes) as ratio from ( $&
            select name, promotes, promobfires, (1- (UNIX_TIMESTAMP(now()) - UNIX_TIMESTAMP(lastaction)) /60/60/24/60) as relevance from Ops $&
            WHERE promotes > 0 AND promobfires > 0 AND server = %servid $&
            ) as tmp where relevance > 0 AND relevance <= 1) as tmp2 $&
            order by -ratio limit 1;


          var %someone = 0
          var %res = $mysql_query(%ma.DB, %sql)
          if (%res) {
            if ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
              var %op = $hget(row, name)
              var %promotes = $hget(row, promotes)
              var %promobfire = $hget(row, promobfires)
              var %cPer = $hget(row, ratio)
              var %realPer = $round($calc(%promobfire / %promotes * 100),2)

              if (%op) {
                %someone = 1
                ;ma.msg $chan The most naive active $ma.getLowOpTitle($chan) $+ + $iif(%op ison $chan,is $+ %op $+ .,is %op $+ .) %realPer $+ $chr(37) ( $+ %promobfire $+ ) of players (s)he has promoted have later gotten themselves demoted or banned.
                ma.msg $chan The most naive active $ma.getLowOpTitle($chan) $+ + is %op $+ $chr(46) %realPer $+ $chr(37) ( $+ %promobfire $+ ) of players (s)he has promoted have later gotten themselves demoted or banned.
              }
            }
            mysql_free %res
          }
          if (%someone == 0) {
            ma.msg $chan No one has yet demoted people that others have promoted.
          }
        }
        else if (%r == 8) {
          var %sql = select ranking, num, title from RankedVisitors where server = %servid order by ranking
          var %res = $mysql_query(%ma.DB, %sql)
          if (%res) {
            var %all = 0
            var %ops = 0
            var %index = 0
            while ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
              var %currank = $hget(row, ranking)
              var %curnum = $hget(row, num)
              var %title = $hget(row, title)

              if (%curnum > 0) {
                %all = $calc(%all + %curnum)
                if (%currank >=  %ma. [ $+ [ $chan ] $+ .LowPromoRank ] ) {
                  %ops = $calc(%ops + %curnum)
                }
                else {
                  inc %index
                  set -e %ma.tmp. [ $+ [ %servid ] $+ .rv. $+ [ %index ] ] $calc(%curnum) %title  
                }
              }
            }
            mysql_free %res

            if (%all >= 100) {
              var %msg = Of our visitors
              if (%index > 0) {
                var %i = 1
                while (%i <= %index) {
                  var %title = $gettok(%ma.tmp. [ $+ [ %servid ] $+ .rv. $+ [ %i ] ] ,2-,32)
                  var %per = $round($calc($calc($gettok(%ma.tmp. [ $+ [ %servid ] $+ .rv. $+ [ %i ] ] ,1,32)) / %all * 100),1)  
                  if (%per > 0) {
                    %msg = %msg $+ , %per $+ $chr(37) $iif(%i == 1,are,$null) %title        
                  }
                  inc %i
                }             

                var %per = $round($calc(%ops / %all * 100),1)
                if (%per > 0) {
                  %msg = %msg $iif(%index > 1,and,$null) %per $+ $chr(37) are moderators.
                }
                else {
                  %msg = %msg or higher
                }
              }
              if (%msg != Of our visitors) {
                ma.msg $chan %msg
              }
              else {
                ma.msg $chan I haven't yet counted enough visitors funfact #8.
              }
            }
            else {
              ma.msg $chan I haven't yet counted enough visitors funfact #8.
            }
            unset %ma.tmp. [ $+ [ %servid ] $+ .rv.* ]
          }

        }
        else if (%r == 9) {

          var %sql = select ROUND((((select AVG(visitors) from stats where server = %servid and date <= (NOW() - INTERVAL 1 DAY) and date >= (NOW() - INTERVAL 15 DAY) ) / AVG(visitors) -1) *100),0) from stats where server = %servid and date <= (NOW() - INTERVAL 1 DAY) and stats.date >= (NOW() - INTERVAL 2 MONTH)
          var %growth = $calc($ma.getDBline(%sql))
          if (%growth > 6) {
            ma.msg $chan We are getting popular. last 2 weeks average of daily visitors was %growth $+ $chr(37) higher than last 2 months average.
          }
          else if (%growth < -6) {
            ma.msg $chan We are getting more refined. last 2 weeks average of daily visitors was $abs(%growth) $+ $chr(37) less than last 2 months average.
          }
          else {
            ma.msg $chan We are going at our usual pace. Our last 2 weeks daily visitor average is pretty much the same as last 2 months average.
          }
        }

        else if (%r == 10) {
          var %sql = select date,kicks,visitors from stats as s1 inner join (select server, max(kicks) as maxkicks from stats where server = %servid ) as s2 on s1.kicks = s2.maxkicks and s1.server=s2.server limit 1;
          var %res = $mysql_query(%ma.DB, %sql)
          if (%res) {
            if ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
              var %thedate = $hget(row, date)
              var %maxkicks = $hget(row, kicks)
              var %visits = $hget(row, visitors)

              ma.msg $chan %thedate is the day when a whopping %maxkicks people were kicked. $iif(%visits > 0,That day we had %visits visitors.)
            }
            mysql_free %res
          }

        }
        ;  else if (%r == 11) {
        ;  }
        else {
          var %yvis = $ma.getDBline(select visitors from Stats where server = %servid AND date = $mysql_qt( $mysql_real_escape_string(%ma.DB,%date) ) ) 
          if (%visitors > 0) {
            ma.msg $chan We get around $round($calc(%visitors / %days),0) visitors daily. Yesterday we had $calc(%yvis)
          }
          else {
            ma.msg $chan I haven't yet counted enough visitors for fun fact #11
          }
        }


        return
      }

      ; Says "np" when thanked. 
      ; Also increases %ma.thanks (which can be used to calculate statistics)
      if ($istok(%ma. [ $+ [ $chan ] $+ .lastreplies ] , $replace(%nick,$chr(32),$chr(44)), 32) ) { 

        var %thanked = 0

        if ( thanks isin %text || thx isin %text || tnx isin %text || thnx isin %text || $regex_w(%text,(ty|danke|arigato)) > 0 || thank you isin %text) {
          if (idiot !isin %text && shit !isin %text && fuck !isin %text && moron !isin %text && nig !isin %text) {
            %thanked = 1

            if (%ma.DB) {
              var %servid = $ma.getServID($chan)
              if (%servid) {
                mysql_exec %ma.DB UPDATE Servers set Thanks = Thanks + 1 Where id = %servid
              }
            }

            set -eu1 %ma. [ $+ [ $chan ] $+ .spam ] 1

            var %ma.np = np;no problem;Always here for you;:3;^^

            ma.msg $chan $gettok(%ma.np,$rand(1,$numtok(%ma.np,59)),59)
          }
        }  

        var %tok = $calc($findtok(%ma. [ $+ [ $chan ] $+ .lastreplies ] ,$replace(%nick,$chr(32),$chr(44)),1,32) + 1)
        var %num = $gettok(%ma. [ $+ [ $chan ] $+ .lastreplies ] , %tok, 32)

        if (%num <= 1 || %thanked == 1) {
          set -eu240 %ma. [ $+ [ $chan ] $+ .lastreplies ] $deltok(%ma. [ $+ [ $chan ] $+ .lastreplies ] ,$calc(%tok - 1) - %tok,32)    
        }
        else {
          set -eu240 %ma. [ $+ [ $chan ] $+ .lastreplies ] $gettok(%ma. [ $+ [ $chan ] $+ .lastreplies ] , 1 - $calc(%tok - 1),32) $calc(%num - 1) $gettok(%ma. [ $+ [ $chan ] $+ .lastreplies ] , $calc(%tok + 1) $+ - ,32)
        }  

      }
    }
  }
}


alias -l ma.spleef {
  var %sec = $calc($2 - %ma.spleef. [ $+ [ $1 ] ] )

  if (%sec > 0) {
    set -e %ma.spleef. [ $+ [ $1 ] ] $calc(%ma.spleef. [ $+ [ $1 ] ] + 1)
    ma.msg $1 %sec
  }
  else {
    unset %ma.spleef. [ $+ [ $1 ] ]
    ma.msg $1 GO!
    .timerma.spleef. $+ $1 off
  }
}

; --------------------------------
; Couple functions for word finding (words that have many forms)
; --------------------------------

alias -l istok_ranks {

  var %text = $1-
  if ($istok(%text,from,32) && ($istok(%text,to,32) || (-> isin $1-))) {
    var %from = $findtok(%text,from,1,32)
    var %to = $calc( $findtok($gettok(%text,%from $+ -,32),to,1,32) + %from -1)
    if (%to < %from) {
      %to = $calc( $wildtok($gettok(%text,%from $+ -,32),*->*,1,32) + %from -1)
    }
    if (%to < %from) {
      %to = $calc( $findtok($gettok(%text,%from $+ -,32),2,1,32) + %from -1)
    }
    if (%to > %from) {
      %text = $gettok(%text,%to $+ -,32)
    }

  }

  ; If short form of ranks is found, add the full
  if ($regex_w(%text,mod)) {
    %text = %text moderator
  }
  if ($regex_w(%text,op)) {
    %text = %text operator
  }
  if ($regex_w(%text,vet)) {
    %text = %text veteran
  }
  if ($regex_w(%text,arch)) {
    %text = %text architect
  }

  if ($findtok(%text,adv,1,32) > 0) {
    var %tok = $v1
    %text = $puttok($deltok(%text,%tok,32),adv $+ $gettok(%text,$calc(%tok + 1),32), %tok,32)
  }
  if ($findtok(%text,advanced,1,32) > 0) {
    var %tok = $v1
    %text = $puttok($deltok(%text,%tok,32),adv $+ $gettok(%text,$calc(%tok + 1),32), %tok,32)
  }

  if ($regex_w(%text,me) == 0 && $regex_w(%text,where) == 0) {

    var %i = 1
    while (%i <= $var(%ma. [ $+ [ $chan ] $+ .RankSetting.* ] ,0 )) {
      var %ranktitle = $gettok($var(%ma. [ $+ [ $chan ] $+ .RankSetting.* ] ,%i ).value,-1,32)
      if (%ranktitle) {
        var %ok = 1
        ;if (($chan) && ($istok(%ma. [ $+ [ $chan ] $+ .name ] , %ranktitle,32)) && (rank !isin %text)) {
        ;  %ok = 0
        ;}
        if (%ok == 1 && $regex_w(%text,%ranktitle)) {
          if ($regex_w(%text,(after|above|next))) {               
            inc %i
          }

          return %i
        }
      }
      inc %i
    }
  }
  return $false
}

alias -l istok_whats {
  if ($regex($lower($1-),(\b(what('s|s)|waht('s|s)|wat('s|s)|wut('s|s)|wtf('s|s))\b|\b(what|waht|wat|wut|wtf)\b \b(is|s)\b) ) > 0) {
    return $true
  }
  return $false
}

alias -l istok_im {
  if (($istok($1-,i,32) && ($istok($1-,m,32) || $istok($1-,am,32))) || ($istok($1-,im,32) || $istok($1-,i'm,32) || $istok($1-,i`m,32) || is I isin $1- || I is isin $1-)) {
    return $true
  }
  return $false
}

alias -l istok_cant {
  if ($istok($1-,cannot,32) || can't isin $1- || can`t isin $1- || cant isin $1- || can not isin $1-) {
    return $true
  }
  return $false

}
alias -l istok_not {
  if (is not isin $1- || isn't isin $1- || isn`t isin $1- || isnt isin $1- || aint isin $1- || ain't isin $1- || ain`t isin $1- ) {
    return $true
  }
  return $false
}

; Checks if player has added himself to ignore list
alias -l ma.is_ignored {
  var %max = $var(%ma. [ $+ [ $2 ] $+ ] .ignored.*,0)
  var %id = 1
  while (%id <= %max) {
    if ($istok($var(%ma. [ $+ [ $2 ] $+ ] .ignored.*,%id).value,$replace($1,$chr(32),$chr(44)),32)) {
      return $true
    }
    inc %id
  }
  return $false
}

alias ma.is_servbot {
  if (($2) && %ma. [ $+ [ $2 ] $+ .botname_set ] ) {
    if ($regex($1,%ma. [ $+ [ $2 ] $+ .botname_set ] ) == 1) {
      if ($3 == 1 || !%ma. [ $+ [ $2 ] $+ .botauth_set ] || (%ma. [ $+ [ $2 ] $+ .botauth_set ] && $istok(%ma. [ $+ [ $2 ] $+ .botauth ] ,$1,32))) {
        return $true
      }
    }
  }
  return $false
}


; --------------------------------
; This function should be called whenever a reply was given.
; Sets spam protection, updates reply stats and announces stats every 1000th reply.
; --------------------------------

alias -l ma.spam {

  ; The spam protection. 
  ; No messages get processed for 1 seconds after a reply.
  set -eu1 %ma. [ $+ [ $2 ] $+ .spam ] 1

  var %nick_sr = $replace($1,$chr(32),$chr(44))

  ; Remember 3 last askers, so they can thank later
  if (!$istok(%ma. [ $+ [ $2 ] $+ .lastreplies ] , %nick_sr,32)) {
    set -eu240 %ma. [ $+ [ $2 ] $+ .lastreplies ] %ma. [ $+ [ $2 ] $+ .lastreplies ] %nick_sr 3
    while ($numtok(%ma. [ $+ [ $2 ] $+ .lastreplies ] ,32) > 6) {
      set -eu240 %ma. [ $+ [ $2 ] $+ .lastreplies ] $deltok(%ma. [ $+ [ $2 ] $+ .lastreplies ] ,1-2,32)
    }
  }
  else {
    set -eu240 %ma. [ $+ [ $2 ] $+ .lastreplies ] %ma. [ $+ [ $2 ] $+ .lastreplies ]
  }

  ; Players may ask up to 5 questions within 5 minute interval, 
  ; otherwise they get ignored for next 30 minutes. (treated as spam)
  noop $ma.incPlayerSpam($2,$1,$3)


  ; Stats update
  var %servid = $ma.getServID($2)
  if (%ma.DB && %servid) {
    mysql_exec %ma.DB UPDATE Servers set Replies = Replies + 1 where id = %servid
    mysql_exec %ma.DB UPDATE Stats set Replies = Replies + 1 where server = %servid AND Date = $mysql_qt( $mysql_real_escape_string(%ma.DB,$date(%ma.datefrm)) )

    ; Stats announcing
    var %replies = $calc($ma.getDBline(select Replies from Servers where id = %servid ))
    if ($len(%replies) > 3 && $right(%replies ,3) == 000) {
      var %first = $ma.GetFirstDate($2)
      var %days = $calc(($ctime($date) - $ctime(%first)) / 86400)
      ma.msg $2 %replies questions answered since %first $+ $chr(46) That's $round($calc(%replies / %days),0) replies per day.
    }
    else if ($len(%replies) > 2) {
      var %len = $v1
      var %i = 2
      while (%i <= %len) {
        if ($mid(replies,1,1) != $mid(%replies,%i,1)) {
          return
        }
        inc %i
      }
      ma.msg $2 Congrats $1 you got the $ord(%replies) answer!
    }

  }

  var %ran = $rand(1,1000)
  if (%ran == 1) {
    ma.msg $2 I love my job! ^^
  }
  else if (%ran == 2) {
    ma.msg $2 Screw my job, Im outta here ><
    part $2
    .timerma.rejoin. $+ $2 1 10 join $2
  }
}

alias ma.GetFirstDate {
  if ($1) {
    if (%ma. [ $+ [ $1 ] $+ ] .FirstDateOn) {
      return $v1
    }
    else {
      var %servid = $ma.getServID($1)
      if (%servid) {
        var %mindate = $ma.getDBline(SELECT min(Date) from Stats where server = %servid )
        if (%mindate) {
          set %ma. [ $+ [ $1 ] $+ .FirstDateOn ] %mindate
          return %mindate
        }
      }
    }
  }
  return $date(%ma.datefrm)
}

alias -l ma.CreateNewServer_2 {
  if ($0 == 3) { 
    if (%ma.DB) {
      var %token = $ma.randword(32) 

      var %botnameregex = / $+ $chr(94) $+ $3 $+ _* $+ $chr(36) $+ /
      ; if ($3 !isvoice $1 && $3 !isop $1 && $3 !ishop $1) {
      ;  echo -a $3 must have voice or op status.
      ;   return
      ; }

      var %sql = insert into Servers (name,token,botname,masterPass) VALUES ( $mysql_qt( $mysql_real_escape_string(%ma.DB,$1) ) , $mysql_qt( %token ) , $mysql_qt( $mysql_real_escape_string(%ma.DB,%botnameregex) ) , $mysql_qt( $mysql_real_escape_string(%ma.DB,$readini($scriptdir $+ ma.ini,n,Website,masterPass)) ) ) 

      if ($mysql_exec(%ma.DB,%sql)) {
        noop $ma.updateSettings()
        ;noop $ma.DBDateCheck()
        var %servid = $ma.getServId($1)
        noop $ma.updateRanks(%servid)

        %sql = INSERT into Stats (Date,Server) VALUES ( $mysql_qt($mysql_real_escape_string(%ma.DB,$date(%ma.datefrm))) , %servid )
        noop $mysql_exec( %ma.DB, %sql )

        fav $iif($2 == 1,%chan)

        if ($2 == 1) {
          msg $gettok(%ma.newserver,2,32) New server created. Choose a password and configure the bot at $readini($scriptdir $+ MA.ini,Website,url) $+ /index.php?token= $+ %token 
        }
        else {
          echo -a New server: $readini($scriptdir $+ MA.ini,Website,url) $+ /index.php?token= $+ %token
        }
      }
      else {
        if ($2 == 1) {
          part $1
        }
        echo -s Failed to add server to database
        echo -s err: %mysql_errstr
        echo -s sql: %sql
      }
    }
    else {
      echo -a Database connection not initiated.
      if ($2 == 1) {
        part $1
      }
    }
  }
}

alias ma.CreateNewServer {
  if ($chan) {
    ma.CreateNewServer_2 $chan 0 $iif($1,$1,$me)
  }
  else {
    echo -a This isn't a channel
  }
}

alias ma.passreset {
  var %chan = $iif($0 == 1 && $me ison $1 , $1 , $chan)
  if (%chan) {
    if (%ma.DB) {
      var %token = $ma.randword(32)
      var %sql = update servers set pass = null, token = $mysql_qt( %token ) where name = $mysql_qt( $mysql_real_escape_string(%ma.DB,%chan) )
      if ($mysql_exec(%ma.DB,%sql)) {           
        $iif($0 == 1,return,echo -a) Password reset link: $readini($scriptdir $+ MA.ini,Website,url) $+ /index.php?token= $+ %token
      }
      else {
        $iif($0 == 1,return,echo -a) Error: Failed create new token
      }
    }
    else {
      $iif($0 == 1,return,echo -a) Error: Database connection not initiated.
    }
  }
  else {
    $iif($0 == 1,return,echo -a) Error: This isn't a channel
  }
}

alias ma.randword {
  var %word = $iif($rand(1,3) <= 2,$rand(a,z),$rand(0,9))
  var %i = 1
  while (%i < $1) {
    %word = %word $+ $iif($rand(1,3) <= 2,$rand(a,z),$rand(0,9))
    inc %i
  }
  return %word
}

on *:SOCKLISTEN:ma.websiteupd:{
  if ($sockerr) {
    return
  }
  var %i = 1
  while ($sock(ma.websiteupd. $+ %i)) {
    inc %i
  }
  sockaccept ma.websiteupd. $+ %i
}

on *:SOCKREAD:ma.websiteupd.*:{

  if ($sockerr) {
    return
  }
  var %data
  sockread -n %data 

  if ($gettok(%data,1,32) == upd_db && $numtok(%data,32) == 2 && $gettok(%data,2,32) isnum) {
    var %servid = $gettok(%data,2,32)
    echo -s $timestamp Website requested settings update for servid: %servid
    noop $ma.updateServSettings(%servid)
  }
  else if ($gettok(%data,1,32) == upd_db_rules && $numtok(%data,32) == 2 && $gettok(%data,2,32) isnum) {    
    var %servid = $gettok(%data,2,32)
    var %serv = $ma.GetServName(%servid)
    echo -s $timestamp Website requested custom rules update for servid: %servid name: %serv
    noop $ma.updateCustomRules(%servid,%serv)
  }
  else if ($gettok(%data,1,32) == upd_ranks && $numtok(%data,32) == 2 && $gettok(%data,2,32) isnum) {  
    var %servid = $calc($gettok(%data,2,32))
    echo -s $timestamp Website requested rank update for servid: %servid
    ma.updateRanks %servid
  }
  else if ($numtok(%data,32) == 3 && ($gettok(%data,1,32) == log || $gettok(%data,1,32) == masterlog)) {

    echo -s $timestamp Logged to website $iif($gettok(%data,1,32) == masterlog,master) config of servid $gettok(%data,2,32) from: $gettok(%data,3,32)
  }
  else if ($gettok(%data,1,32) == reg) {
    var %regchan = $gettok(%data,2,32)
    set -eu3600 %ma.lastregs $addtok(%ma.lastregs,%regchan,32)
    echo -s New registration: %regchan
  }
  else {
    echo -s $timestamp Invalid data from website: %data
  }
  sockclose $sockname
}

alias ma.updateRanks {
  if (%ma.DB) {
    var %query = select name, MultiColorValue, PromoRank, SpleefRank, MuteRank, WaterRank from Servers where id = $1
    var %res = $mysql_query(%ma.DB,%query)
    if (%res) {
      if ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
        var %serv = $hget(row, name)
        set %ma. [ $+ [ %serv ] $+ .MulticolorValue ] $hget(row, MultiColorValue)
        set %ma. [ $+ [ %serv ] $+ .LowPromoRank ] $hget(row, PromoRank)
        set %ma. [ $+ [ %serv ] $+ .LowSpleefRank ] $hget(row, SpleefRank)
        set %ma. [ $+ [ %serv ] $+ .LowMuteRank ] $hget(row, MuteRank)
        set %ma. [ $+ [ %serv ] $+ .LowWaterRank ]  $hget(row, WaterRank)

        mysql_free %res

        %query = select Ranking, Color, Prefix, Promoto, Title from RankedVisitors where server = $1 order by Ranking
        var %res = $mysql_query(%ma.DB,%query)
        if (%res) {        
          unset %ma. [ $+ [ %serv ] $+ .RankSetting.* ]
          var %i = 1

          while ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
            set %ma. [ $+ [ %serv ] $+ .RankSetting. $+ [ %i ] ] $hget(row, Ranking) $hget(row, Color) $hget(row, Prefix) $hget(row, Promoto) $replace($hget(row, Title),$chr(32),_)
            inc %i
          }
          mysql_free %res
        }
        else {
          echo -s MA: Couldn't update ranks q2. %mysql_errstr
          echo -s sql was %query
        }
      }
      else {
        mysql_free %res
      }
    }
    else {
      echo -s MA: Couldn't update ranks q1. %mysql_errstr
      echo -s sql was %query
    }
  }
}

alias ma.updateServSettings {

  if ($0 != 1 || $1 !isnum) {
    return
  }

  var %servid = $1

  var %query = select name, botauth, ranks, impersonation, funfacts, jokes, pony, botname, website, dispname, howtofly, muted, hidesilent, multilang, disableplayers from Servers where id = %servid
  var %res = $mysql_query(%ma.DB,%query)
  if (%res) {
    if ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) { 
      var %serv = $hget(row, name)
      var %botauth = $hget(row, botauth)
      var %botname = $hget(row, botname)

      if (%serv) {

        var %reauth = 0
        if (%botauth != %ma. [ $+ [ %serv ] $+ .botauth_set ] || %botname != %ma. [ $+ [ %serv ] $+ .botname_set ] || $len(%ma. [ $+ [ %serv ] $+ .botauth ] ) == 0 || $len(%botauth) == 0) {
          %reauth = 1
        }
        set %ma. [ $+ [ %serv ] $+ .botname_set ] %botname
        set %ma. [ $+ [ %serv ] $+ .botauth_set ] %botauth
        set %ma. [ $+ [ %serv ] $+ .rank_set ] $hget(row, ranks)
        set %ma. [ $+ [ %serv ] $+ .impersonation ] $hget(row, impersonation)
        set %ma. [ $+ [ %serv ] $+ .funfact_set ] $hget(row, funfacts)
        set %ma. [ $+ [ %serv ] $+ .jokes_set ] $hget(row, jokes)
        set %ma. [ $+ [ %serv ] $+ .themes_set ] $hget(row, pony)
        set %ma. [ $+ [ %serv ] $+ .website ] $hget(row, website)
        set %ma. [ $+ [ %serv ] $+ .name ] $hget(row, dispname)
        set %ma. [ $+ [ %serv ] $+ .howtofly ] $hget(row, howtofly)
        set %ma. [ $+ [ %serv ] $+ .mute ] $hget(row, muted)
        set %ma. [ $+ [ %serv ] $+ .hidesilent ] $hget(row, hidesilent)
        set %ma. [ $+ [ %serv ] $+ .multilang ] $hget(row, multilang)
        set %ma. [ $+ [ %serv ] $+ .disableplayers ] $hget(row, disableplayers)

        if (%reauth == 1) {
          unset %ma. [ $+ [ %serv ] $+ .botauth ]
          if ($len(%ma. [ $+ [ %serv ] $+ .botauth_set ] ) > 0) {
            ma.FindAuthServBot %serv
          }
        }
      }
    }
    mysql_free %res
  }
  else {
    echo -s MA Setting update failed. %mysql_errstr
    echo -s sql was: %query
  }

}

alias ma.updateSettings {
  if (%ma.DB) {

    unset %ma.servers

    var %query = select name from Servers where Active = 1
    var %res = $mysql_query(%ma.DB,%query)
    if (%res) {
      while ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
        set %ma.servers $addtok(%ma.servers,$hget(row, name),32)
      }
    }

    var %i = $numtok(%ma.servers,32)
    while (%i >= 1) {
      var %serv = $gettok(%ma.servers,%i,32)
      var %servid = $ma.getServId(%serv)
      if (%servid) {
        noop $ma.updateServSettings(%servid)        
        noop $ma.updateCustomRules(%servid,%serv)
      }
      dec %i
    }
  }
}

alias -l ma.updateCustomRules {
  if ($0 == 2 && $1 isnum) {
    var %query = select regmatch, reply from CustomRules where server = $1 and enabled = 1
    var %res = $mysql_query(%ma.DB,%query)
    if (%res) {
      unset %ma. [ $+ [ $2 ] $+ .CustomRule.M.* ]
      unset %ma. [ $+ [ $2 ] $+ .CustomRule.R.* ]
      var %i = 1
      while ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
        if ($hget(row, regmatch) && $hget(row, reply)) {
          set %ma. [ $+ [ $2 ] $+ .CustomRule.M. $+ [ %i ] ] $hget(row, regmatch)
          set %ma. [ $+ [ $2 ] $+ .CustomRule.R. $+ [ %i ] ] $hget(row, reply)
          inc %i
        }
      }
      mysql_free %res
    }
  }
}

alias ma.getLowOpTitle {
  if ($1) {
    var %i = 1
    var %curv = $null
    var %curt = $null
    while (%i <= $var(%ma. [ $+ [ $1 ] $+ .RankSetting.* ] ,0)) {
      var %set = $var(%ma. [ $+ [ $1 ] $+ .RankSetting.* ] ,%i).value
      if ($calc($gettok(%set,1,32)) >= $calc(%ma. [ $+ [ $1 ] $+ .LowPromoRank ] )) {
        if (!%curv || %curv > $calc($gettok(%set,1,32))) {
          %curv = $calc($gettok(%set,1,32))
          %curt = $replace($gettok(%set,-1,32),_,$chr(32))
        }
      } 
      inc %i
    }
    return %curt
  }
  return $null
}
alias ma.getHighestRankValue {
  var %cur = 0
  if ($1) {
    var %i = 1
    while (%i <= $var(%ma. [ $+ [ $1 ] $+ .RankSetting.* ] ,0)) {
      if ($calc($gettok( $var(%ma. [ $+ [ $1 ] $+ .RankSetting.* ] ,%i).value ,1,32)) > %cur) {
        %cur = $v1
      } 
      inc %i
    }

  }
  return %cur
}

alias -l ma.idToColor {
  if ($1 == 0) { return white }
  if ($1 == 1) { return black }
  if ($1 == 2) { return navy(blue) }
  if ($1 == 3) { return green }
  if ($1 == 4) { return red }
  if ($1 == 5) { return maroon(red) }
  if ($1 == 6) { return purple }
  if ($1 == 7) { return olive }
  if ($1 == 8) { return yellow }
  if ($1 == 9) { return lime }
  if ($1 == 10) { return teal }
  if ($1 == 11) { return aqua }
  if ($1 == 12) { return blue }
  if ($1 == 13) { return magenta(pink) }
  if ($1 == 14) { return grey }
  if ($1 == 15) { return silver }
  return $null
}
alias regex_w {
  return $regex($lower($1),\b $+ $lower($2) $+ [^0-9a-z_]*\b)
}
alias ma.incPlayerSpam {
  if ($2) {
    if ((!$3 || !%ma. [ $+ [ $1 ] $+ .LowPromoRank ] ) || (($3) && (%ma. [ $+ [ $1 ] $+ .LowPromoRank ] ) && $3 < %ma. [ $+ [ $1 ] $+ .LowPromoRank ] ) ) {
      var %spammer = $replace($2,$chr(32),$chr(44))
      set -eu240 %ma. [ $+ [ $1 ] $+ .spam. $+ [ %spammer ] ] $calc((%ma. [ $+ [ $1 ] $+ .spam. $+ [ %spammer ] ] ) + $iif($4,$calc($v1),1))
      if (%ma. [ $+ [ $1 ] $+ .spam. $+ [ %spammer ] ] > 5) {
        set -eu1800 %ma. [ $+ [ $1 ] $+ .spam. $+ [ %spammer ] ] 6
      }
    }
  }
}

on 1:DNS:{
  if ($var(%ma.DNS.*,0) > 0) {
    var %i = $dns(0)
    while (%i > 0) {
      var %nick = $dns(%i).nick
      var %addr = $dns(%i).addr
      if (%ma.DNS. [ $+ [ %nick ] ] ) {

        var %pair = $gettok(%ma.DNS. [ $+ [ %nick ] ] ,1,32 )
        var %pair_p = %pair
        var %nick_p = %nick
        if ($left(%pair,1) == @ || $left(%pair,1) == +) {
          %pair = $right(%pair,-1)
        }
        else {
          %pair_p = $gettok(%ma.DNS. [ $+ [ %pair ] ] ,1,32 )
          %nick_p = %pair
        }

        if ( $gettok(%ma.DNS. [ $+ [ %pair ] ] ,3,32) ) {
          var %pair_addr = $v1
          if (%pair_addr != %addr) {
            var %chan = $gettok(%ma.DNS. [ $+ [ %nick ] ] ,2,32 )
            if ($me ison %chan) {
              set -eu45 %ma. [ $+ [ %chan ] $+ .impersonation. $+ [ %nick ] ] 1
              set -eu1 %ma. [ $+ [ %chan ] $+ .spam ] 1
              ma.msg %chan Random user %nick_p has similiar nick to %pair_p $+ . Possible impersonation? IRC op or voiced person may allow him by voicing him or typing !allow %nick_p
            }
          }
          else {
          }
          unset %ma.DNS. [ $+ [ %nick ] ]
          unset %ma.DNS. [ $+ [ %pair ] ]
        }
        else {
          set -eu10 %ma.DNS. [ $+ [ %nick ] ] $addtok(%ma.DNS. [ $+ [ %nick ] ] , %addr,32)
        }
      }
      dec %i
    }
    haltdef
  }
}

alias -l ma.IsOnChan {
  if ($me ison $1) {
    return $cid
  }
  var %i = $scon(0)
  while (%i > 0) {
    scon %i
    if ($me ison $1) {
      return $scon(%i).cid
    }
    dec %i
  }
  return 0
}
alias -l ma.msg {
  msg $1-
}
alias ma.tell {
  var %i = $numtok(%ma.servers,32)
  while (%i > 0) {
    var %chan = $gettok(%ma.servers,%i,32)
    if ($ma.isonchan(%chan)) {
      scid $v1
      if ($nick(%chan,0) > 1) {
        var %max = $nick(%chan,0)
        var %z = 1
        while (!$ma.is_servbot($nick(%chan,%z),%chan) && %z <= %max) {
          inc %z
        }
        if (%z <= %max) {
          msg %chan [Broadcast] $1-
        }
        else {
          echo -s tell skipped %chan
        }
      }
    }
    dec %i
  }
}
alias ma.mergeop {
  if (%ma.DB && $chan && $0 == 2) {
    var %servid = $calc($ma.getservid($chan))
    var %servid2 = $2
    var %player = $3
    var %sql = select id, kicks, bans, promotes, demotes, promobfires from ops where server = %servid and name = $mysql_qt($mysql_real_escape_string(%ma.DB,%player))
    var %res = $mysql_query(%ma.DB,%sql)
    if (%res) {
      if ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {

        var %id = $hget(row, id)
        var %kicks = $hget(row, kicks)
        var %bans = $hget(row, bans)
        var %promotes = $hget(row, promotes)
        var %demotes = $hget(row, demotes)
        var %promobfires = $hget(row, promobfires)

        %sql = select id from ops where server = %servid and name = $mysql_qt($mysql_real_escape_string(%ma.DB,$1))
        var %newopid = $ma.getdbline(%sql)
        if (%newopid) {
          %sql = update ops set kicks=kicks + %kicks , bans=bans + %bans , promotes=promotes + %promotes , demotes=demotes + %demotes , promobfires=promobfires + %promobfires where id = %newopid
          if ($mysql_exec(%ma.DB,%sql)) {
            %sql = update promoted set promoter = %newopid where promoter = %id
            if ($mysql_exec(%ma.DB,%sql)) {
              %sql = delete from ops where id = %id
              if ($mysql_exec(%ma.DB,%sql)) {
                echo -a Success!
              }
              else {
                echo -a sql error4: %sql
              }
            }
            else {
              echo -a sql error3: %sql
            }
          }
          else {
            echo -a sql error2: %sql
          }
        }
        else {
          echo -a No such op: $1
        } 
      }
      else {
        echo -a No such op: $2
      }
      mysql_free %res
    }
    else {
      echo -a sql error1: %sql
    }

  }
}
alias ma.removeserver {
  if ($chan) {
    var %servid = $calc($ma.getservid($chan))
    if (%servid > 0) {

      set %ma.servers $remtok(%ma.servers,$chan,0,32)
      .timerma. $+ $chan $+ .* off

      var %sql = delete from logins where server = %servid
      noop $mysql_query(%ma.DB,%sql)
      %sql = delete from stats where server = %servid
      noop $mysql_query(%ma.DB,%sql)
      %sql = delete from rankerrors where server = %servid
      noop $mysql_query(%ma.DB,%sql)
      %sql = delete from rankedvisitors where server = %servid
      noop $mysql_query(%ma.DB,%sql)
      %sql = delete from promoted where server = %servid
      noop $mysql_query(%ma.DB,%sql)
      %sql = delete from ops where server = %servid
      noop $mysql_query(%ma.DB,%sql)
      %sql = delete from customrules where server = %servid
      noop $mysql_query(%ma.DB,%sql)
      %sql = delete from online where server = %servid
      noop $mysql_query(%ma.DB,%sql)
      %sql = delete from servers where id = %servid
      noop $mysql_query(%ma.DB,%sql)

      unset %ma. [ $+ [ $chan ] $+ .* ] 

      echo -a Removed $chan ( id: %servid )

    }
    else {
      echo -a Server not found in database
    }
  }
  else {
    echo -a This is not a channel
  }
}

alias urlencode {
  var %a = $regsubex($$1,/([^\w\s])/Sg,$+(%,$base($asc(\t),10,16,2)))
  return $replace(%a,$chr(32),$chr(43))
}

on 1:EXIT:{ if (%ma.DB) { mysql_close %ma.DB } }
on 1:UNLOAD:{ if (%ma.DB) { mysql_close %ma.DB } }
