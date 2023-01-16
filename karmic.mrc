;;for f (freenode head of staff), andrewbro, tintle and friends
;;right click channel for options
;;right click nicklist for options
;;Made with love, Shane 2022

on *:connect:{
  .timerloadkarma 1 10 load.karma
  .timersavekarma 0 900 save.karma
  config.set
}
on *:start:{
  config.set
  echo -ts 48[14Karmic48]60: Keepin' it real since $date(yyyy)
}

alias config.set {
  ;;karma that bot considers good in order to consier them authentic (for modes and stuff)
  ;;edit line below
  var %goodkarma = 0.15
  var %polltime = 5m (add later: time for poll expirery)
  hadd -m good karma %goodkarma
  ;;turn minutes in to seconds
  hadd -m poll time $calc($replace(%polltime,m,* 60))
}

alias goodkarma {
  if ($1 != $null) && ($1 isnum) { hadd -m good karma $1 | echo -tsa * Set Good Karma to: $1 }
  return $hget(good,karma)
}

on ^*:join:#:{
  kstream $nick $+ : $+ $karma($nick,$network) joined $chan
  .timerseenuserscan. $+ $network $+ . $+ $chan 1 $r(300,600) seenuserscan $chan
  hadd -mu300 recentjoin. $+ $network $+ . $+ $chan $nick 1
  if ($karma($nick,$network) < $goodkarma) { ignorekarma $nick $network 300 }
  if ($hget(autokb. $+ $network,$chan) != $null) {
    if ($karma($nick,$network) <= $hget(autokb. $+ $network,$chan)) {
      if ($me isop $chan) { raw -q mode $chan +b $address($nick,4) $+ $lf $+ kick $chan $nick -karmic }
    }
  }
  if ($nick != $me) {
    if ($left($nick,4) == web-) && ($network == freenode) {
      if ($hget(greet. $+ $network,$chan) != $null) {
        .notice $nick $hget(webgreet. $+ $network,$chan)
      }
    }
    if ($hget(greet. $+ $network,$chan) != $null) && ($karma($nick,$network) <= $goodkarma) {
      .notice $nick $hget(greet. $+ $network,$chan)
    }
    if ($hget(amode. $+ $network,$chan) != $null) {
      .timer 1 $r(35,75) { modeifgood $nick $chan $hget(amode. $+ $network,$chan)  }
    }
    hinc -m join. $+ $network $nick 1
    if ($hget(ns.name,$nick) == $null) && ($karma($nick,$network) <= $goodkarma)  {
      .timernsinfo. $+ $network $+ . $+ $nick 1 $r(1,35) .nsinfo $nick
    }
  }
  if ($hget(ij. $+ $network,$chan) == 1) && ($karma($nick,$network) < $goodkarma) { halt }
}


alias nsinfo { }
alias prblems {
  var %f = problems. $+ $1 $+  $md5($2)
  if (%f == 0) { msg $2 There are 0 problems registered for $chan - Say wtp for more info! | halt }
  var %a = 1 | var %b = $lines(%f)
  echo -ta %a %b
  while (%a <= %b) {
    msg $2 09,01Needs Solution:00 $read(%f,%a)
    inc %a
  }
}

alias suggestions {
  var %f = solutions. $+ $1 $+  $md5($2)
  if (%f == 0) { msg $2 There are 0 suggestions offered - Say wtp for more info!  | halt }
  var %a = 1 | var %b = $lines(%f)
  echo -ta %a %b
  while (%a <= %b) {
    msg $2 09,01Suggestion:00 $read(%f,%a)
    inc %a
  }
}

alias pollchan {
  if ($hget(pollchan. $+ $1,$2) != $null) { msg $chan Poll already being counted. Please wait the full 5minutes. | halt }
  hadd -mu300 pollchan. $+ $1 $2 $3-
  hadd -mu300 pollchan.total. $+ $1 $2 0
  hadd -mu300 pollchan.totalyes. $+ $1 $2 0
  hadd -mu300 pollchan.totalno. $+ $1 $2 0
  msg $2 09,01[5min] Poll y(es) or n(o) :00 $strip($3-) 
  .timerpollchan. $+ $1 $+ . $+ $2 1 301 pollchanend $1 $2
}
alias pollchanend {
  var %total = $hget(pollchan.total. $+ $1,$2)
  var %yes = $hget(pollchan.totalyes. $+ $1,$2)
  var %no = $hget(pollchan.totalno. $+ $1,$2)
  if (%total == $null) { var %total = 0 }
  if (%yes == $null) { var %yes = 0 }
  if (%no == $null) { var %no = 0 }
  msg $2 09,0114[09 Poll Ended 14]00 Total votes: %total [Yes: %yes $+ /No: %no $+ ]
  .hdel pollchan.total. $+ $1 $2
  .hdel pollchan.totalyes. $+ $1 $2
  .hdel pollchan.totalno. $+ $1 $2
  .hdel pollchan. $+ $1 $2
  .hdel -w pollchan.yes. $+ $network $+ . $+ $chan *
  .hdel -w pollchan.no. $+ $network $+ . $+ $chan *
  .timerpoll.* $+ $2 $+ * off
}

alias botmode {
  if ($me ison $active) && ($1 == on) { hadd -m botmode $chan 1 | echo -ta Bot mode for channel $active is now on }
  if ($me ison $active) && ($1 == off) { hdel botmode $chan 1 | echo -ta Bot mode for channel $active is now off }
}


on *:ban:#:{
  kstream $nick $+ : $+ $karma($nick,$network) banned $bnick $+ : $+ $karma($bnick,$network)
  if ($banmask iswm $ial($me)) && ($me isop $chan) {
  }
}

alias unbanme {
  if ($me isop $1) {
    var %a = 1 | var %b = $banlist($chan,0) | var %c = 0
    while (%a <= %b) {
      if ($banlist($chan,%a) iswm $ial($me)) { mode $chan -b $banlist($chan,%a) | inc %c }
      inc %a
    }
  }
}

alias save.karma {
  scid -a loop.chans
}

alias load.karma {
  scid -a gload.karma
}

alias gload.karma {
  var %a = 1 | var %b = $lines($network $+ .karma.ini)
  while (%a <= %b) {
    var %line = $read($network $+ .karma.ini,%a)
    var %nick = $gettok(%line,1,$asc(=))
    var %karma = $gettok(%line,2,$asc(=))
    if ($gettok(%line,0,$asc(=)) >= 1) && ($chr($asc([)) !isin %line) {
      if ($karma(%nick,$network) != $null) && ($hget(nre. $+ $network,%nick) == $null) {
        setkarma $gettok(%line,1,$asc(=)) $gettok(%line,2,$asc(=)) | hadd -mu3 nre. $+ $neetwork %nick 1
      }
    }
    inc %a
  }
}

alias loop.chans {
  var %a = 1 | var %b = $chan(0)
  while (%a <= %b) {
    loop.nicks $chan(%a)
    inc %a
  }
}

alias loop.nicks {
  var %a = 1 | var %b = $nick($1,0)
  while (%a <= %b) {
    var %nick = $nick($1,%a)
    if ($karma(%nick,$network) >= $goodkarma) { writeini $network $+ .karma.ini $network %nick $karma(%nick,$network) }
    inc %a
  }
}

alias add.friend {
  hadd -m friend. $+ $network $1 1
  hadd -m friend $1 1
  writeini friends.ini $1 1
}

alias rem.friend {
  hadd -m friend. $+ $network $1 0
  hadd -m friend $1 0
  writeini friends.ini $1 0
}
alias isfriend {
  if ($hget(friend,$1) != $null) { return 1 }
  if ($hget(friend,$1) == $null) { return 0 }
  if ($hget(friend,$1) == 0) { return 0 }
}

on ^*:text:*:#:{
  if ($hget(autoshunwords. $+ $network,$chan) != $null) && ($karma($nick,$network) < $goodkarma) {
    var %a = 1 | var %b = $gettok($hget(autoshunwords. $+ $network,$chan),0,32)
    while (%a <= %b) {
      if ($gettok($hget(autoshunwords. $+ $network,$chan),%a,32) iswm $1-) {
        echo -ti $chan * Auto shun word $gettok($hget(autoshunwords. $+ $network,$chan),%a,32) detected. Applying shun.
        shun $nick 36h flood/spam
        halt
      }
      inc %a
    }
  }
  if ($hget(autobanwords. $+ $network,$chan) != $null) && ($karma($nick,$network) < $goodkarma) {
    var %a = 1 | var %b = $gettok($hget(autoshunwords. $+ $network,$chan),0,32)
    while (%a <= %b) {
      if ($gettok($hget(autoshunwords. $+ $network,$chan),%a,32) iswm $1-) {
        echo -ti $chan * Auto ban word $gettok($hget(autoshunwords. $+ $network,$chan),%a,32) detected. Applying ban.
        if ($network == freenode) { cs quiet $chan +24h $address($nick,4) | halt }
        if ($network != freenode) { mode $chan +b $address($nick,4) | halt }
        halt
      }
      inc %a
    }
  }
  ;if ($1 == !bang) || ($1 == !shop) || ($1 == !reload) && ($hget(ignoreducks. $+ $network,$chan) == 1) { halt }
  ;if ( isin $1-) && (Duck isin $nick) && ($hget(ignoreducks. $+ $network,$chan) == 1) { halt }
  if ($hget(ignorebk. $+ $network,$chan) == 1) && ($karma($nick,$network) < $goodkarma) { halt }
  kstream $chan 4<15 $+ $nick $+ 4:14 $+ $karma($nick,$network) $+ 4>0 $1-
  hinc -mu604800 msg. $+ $network $nick 0.1
  hinc -mu604800 msg. $+ $network $+ . $+ $chan $nick 1
  hinc -mu5 recenttalk. $+ $network $+ . $+ $chan $nick 1
  if ($hget(ibk. $+ $network,$chan) == 1) && ($karma($nick,$network) < $goodkarma) { halt }
  if ($right($1,1) == $chr($asc(:))) || ($right($1,1) == $chr(44)) {
    if ($remove($1,$chr(44),:) ison $chan) {
      var %vnick = $remove($1,$chr(44),:)
      if ($karma(%vnick) >= $goodkarma) && ($karma($nick) >= $goodkarma)  {
        hinc -mu804600 vibes. $+ $network %vnick 1 
      }
    }
  }
  if ($nick isop $chan) || ($nick ishop $chan) && ($karma($nick,$network) >= $goodkarma) {
    if ($1 == unban) && ($2 != $null) {
      var %a = 1 | var %b = $banlist($chan,0) | var %c = 0
      while (%a <= %b) {
        if ($2 isin $banlist($chan,%a)) || ($ial($banlist($chan,%a) != $null) { mode $chan -b $banlist($chan,%a) | inc %c }
        inc %a
      }
      msg $chan %c bans matching removed
    }
  }
  if ($hget(recenttalk. $+ $network $+ . $+ $chan,$nick) >= 3) {
    hinc -mu604800 times.flood. $+ $network $nick 1
    if ($karma($nick,$network) <= $goodkarma) && ($hget(recentjoin. $+ $network $+ . $+ $chan,$nick) == 1) {
      if ($hget(banflood. $+ $network,$chan) == 1) {
        if ($network == freenode) { cs quiet $chan +6h $address($nick,4) spam/flood }
        if ($network != freenode) {
          mode $chan +b $address($nick,4)
        }
        hdel recenttalk. $network $+ . $+ $chan $nick
      }
      if ($hget(shunflood. $+ $network,$chan) == 1) {
        shun $nick 6h flood/spam
        hdel recenttalk. $network $+ . $+ $chan $nick
      }
      if ($hget(kbflood. $+ $network,$chan) == 1) {
        mode $chan +b $address($nick,4) | kick $chan $nick
        hdel recenttalk. $network $+ . $+ $chan $nick
      }
    }
  }
  if ($hget(botmode. $+ $network,$chan) == 1) && ($karma($nick,$network) >= $goodkarma) {
    if ($hget(pollchan. $+ $network,$chan) != $null) {
      if ($1 == end) {
        if ($2 == poll) { pollchanend $network $chan }
      }
      if ($1 == y) || ($1 == yes) || ($1 == 1) || ($1 == n) || ($1 == no) {
        if ($1 == y) || ($1 == yes) {
          if ($hget(yes. $+ $network $+ . $+ $chan,$address($nick,4)) != $null) { notice $nick You already voted. | halt }
          if ($hget(no. $+ $network $+ . $+ $chan,$address($nick,4)) != $null) { notice $nick You already voted. | halt }
          hinc -mu300 pollchan.total. $+ $network $chan 1
          hinc -mu300 pollchan.totalyes. $+ $network $chan 1
          hadd -mu300 yes. $+ $network $+ . $+ $chan $address($nick,4) 1
          echo -t $chan Vote for yes registered
        }
        if ($1 == n) || ($1 == no) {
          if ($hget(yes. $+ $network $+ . $+ $chan,$address($nick,4)) != $null) { notice $nick You already voted. | halt }
          if ($hget(no. $+ $network $+ . $+ $chan,$address($nick,4)) != $null) { notice $nick You already voted. | halt }
          hinc -mu300 pollchan.total. $+ $network $chan 1
          hinc -mu300 pollchan.totalno. $+ $network $chan 1
          hadd -mu300 no. $+ $network $+ . $+ $chan $address($nick,4) 1
          echo -t $chan Vote for yes registered
        }
      }
    }
    if ($1 == karma) && ($2 != $null) {
      msg $chan $2 has $karma($2,$network)
    }
    if ($1 == vibes) && ($2 != $null) {
      if ($hget(vibes. $+ $network,$2) != $null) { msg $chan $2 has $karma($2,$network) karma and $hget(vibes. $+ $network,$2) vibes }
    }
    if ($right($1,2) == ++) {
      hinc -mu604800 vibes. $+ $network $left($1,-2)
    }
    if ($1 == automode) {
      if ($2 == on) && ($3 != $null) {
        if ($nick !isreg $chan) && ($me isop $chan) {
          hadd -m amode. $+ $network $chan $3
          msg $chan I'll set modes on users that meet certain metrics.
        }
      }
      if ($2 == off) {
        hdel amode. $+ $network $chan
        msg $chan no longer setting modes on users
      }
    }
    if ($1 == poll) { pollchan $network $chan $strip($2-) }
    if ($1 == rethink) {
      var %f = problems. $+ $network $+  $md5($chan)
      var %y = solutions. $+ $network $+  $md5($chan)
      msg $chan Resetting problem board and suggestion board for $chan from $lines(%f) problems and $lines(%y) suggestions
      .remove %f
      .remove %y
    }
    if ($1 == problem) && ($4 != $null) {
      write problems. $+ $network $+ $md5($chan) $strip($2-)
      notice $nick Registered $chan problem. A reminder prompt will be given for users to solve it.
      .msg $chan 00,01Registered $chan problem. A reminder prompt will be given for users to solve it.
      .msg $chan 00,09There are $lines(problems. $+ $network $+  $md5($chan)) pending
    }
    if ($1 == suggestion) && ($4 != $null) {
      var %f = problems. $+ $1 $+  $md5($2)
      if (%f == 0) {  msg $chan  00,01 $+ $nick $+ 14:15 there are no registered problems. Say "problem some information here" }
      write solutions. $+ $network $+ $md5($chan) $strip($2-)
      msg $chan 00,01 $+ $nick $+ 14:15 added solution to the main list for $chan - Thank you for your contribution.
    }
    if ($1 == problems) {
      msg $chan 00,01 $+ $nick $+ 14:15 there are $lines(problems. $+ $network $+  $md5($chan)) pending issues needing resolution
      prblems $network $chan
    }

    if ($1 == suggestions) {
      msg $chan 00,01 $+ $nick $+ 14:15 there are $lines(solutions. $+ $network $+  $md5($chan)) solutions for $lines(problems. $+ $network $+  $md5($chan)) registered problems
      suggestions $network $chan
    }
    if ($1 == wordscore) || ($1 == wordcount) {
      msg $chan Seen $2 $wordscore($2) times
    }
    if ($1 == wtp) {
      wtp $chan
    }
    if ($hget(lastmsgnick. $+ $network,$chan) != $nick) {
      if ($hget(lastmsg. $+ $network,$chan)  != $null) && ($calc($ctime - $hget(lastmsg. $+ $network,$chan)) <= 2) {
        hinc -m respondsfast. $+ $network $nick 1
        echo -ts $nick on $chan sends messages within 3 seconds when another user chats
      }
    }
  }
}
on *:action:*:*:{
  kstream $chan 4<15 $+ $nick $+ 4:14 $+ $karma($nick,$network) $+ 4>0 $1-
  hinc -mu604800 action. $+ $network $nick 1
  hinc -mu604800 action. $+ $network $+ . $+ $chan  $nick 1
  hinc -mu300 recenttalk. $+ $chan $nick 1
  if ($hget(recenttalk.. $+ $chan,$nick) >= 3) { hinc -mu604800 times.flood. $+ $network $nick 1 }
  if ($hget(lastmsgnick. $+ $network,$chan) != $nick) {
    if ($hget(lastmsg. $+ $network,$chan)  != $null) && ($calc($ctime - $hget(lastmsg. $+ $network,$chan)) <= 3) {
      hinc -m respondsfast. $+ $network $nick 1
      echo -ts $nick on $chan sends messages within 3 seconds when another user chats
    }
  }
  if ($chan != $null) {
    hinc -m msg. $+ $network $nick 1
  }
  hadd -m lastmsg. $+ $network $chan $ctime
  hadd -m lastmsgnick. $+ $network $chan $nick
}

on *:mode:#:{
  kstream $nick $+ : $+ $karma($nick,$network) mode $1-
  hinc -mu604800 mode. $+ $network $nick 1
  hinc -m mode. $+ $network $nick 1
}

on *:kick:#:{
  kstream $nick $+ : $+ $karma($nick,$network) kicked $knick $+ : $+ $karma($knick,$network)
  hinc -mu604800 kick. $+ $network $nick 1
  hinc -mu604800 kicked. $+ $network $knick 1
  hinc -mu604800 kick. $+ $network $+ . $+ $chan nick 1
  hinc -mu604800 kicked. $+ $network $+ . $+ $chan $knick 1
}
on *:owner:#:{
  kstream $nick $+ : $+ $karma($nick,$network) ownered $opnick $+ : $+ $karma($opnick,$network)
  hinc -mu604800 owner. $+ $network $nick 1
  hinc -mu604800 ownered. $+ $network $opnick 1
  hinc -mu604800 owner. $+ $network $+ . $+ $chan $nick 1
  hinc -mu604800 ownered. $+ $network $+ . $+ $chan $opnick 1
}
on *:deowner:#:{
  kstream $nick $+ : $+ $karma($nick,$network) deownered $opnick $+ : $+ $karma($opnick,$network)
  hinc -mu604800 deowner. $+ $network $nick 1
  hdec -mu604800 deownered. $+ $network $opnick 1
  hinc -mu604800 deowner. $+ $network $+ . $+ $chan $nick 1
  hinc -mu604800 deownered. $+ $network $+ . $+ $chan $opnick 1
}
on *:admin:#:{
  kstream $nick $+ : $+ $karma($nick,$network) adminned $opnick $+ : $+ $karma($opnick,$network)
  hinc -mu604800 admin. $+ $network $nick 1
  hinc -mu604800 adminned. $+ $network $opnick 1
  hinc -mu604800 admin. $+ $network $+ . $+ $chan $nick 1
  hinc -mu604800 adminned. $+ $network $+ . $+ $chan $nick $opnick 1
}
on *:deadmin:#:{
  kstream $nick $+ : $+ $karma($nick,$network) deadminned $opnick $+ : $+ $karma($opnick,$network)
  hinc -mu604800 deadmin. $+ $network $nick 1
  hinc -mu604800 deadminned. $+ $network $opnick 1
  hinc -mu604800 deadmin. $+ $network $+ . $+ $chan $nick 1
  hdec -mu604800 deadminned. $+ $network $+ . $+ $chan $opnick 1
}
on *:op:#:{
  kstream $nick $+ : $+ $karma($nick,$network) opped $opnick $+ : $+ $karma($opnick,$network)
  hinc -mu604800 op. $+ $network $nick 1
  hinc -mu604800 opped. $+ $network $opnick 1
  hinc -mu604800 op. $+ $network $+ . $+ $chan $nick 1
  hinc -mu604800 opped. $+ $network $+ . $+ $chan $opnick 1
}
on *:deop:#:{
  kstream $nick $+ : $+ $karma($nick,$network) deopped $opnick $+ : $+ $karma($nick,$network)
  hinc -mu604800 deop. $+ $network $nick 1
  hinc -mu604800 deopped. $+ $network $opnick 1
  hinc -mu604800 deop. $+ . $+ $chan $network $nick 1
  hinc -mu604800 deopped. $+ . $+ $chan $network $opnick 1
}
on *:halfop:#:{
  kstream $nick $+ : $+ $karma($nick,$network) halfopped $opnick $+ : $+ $karma($opnick,$network)
  hinc -mu604800 halfop. $+ $network $nick 1
  hinc -mu604800 halfopped. $+ $network $opnick 1
  hinc -mu604800 halfop. $+ $network $+ . $+ $chan $nick 1
  hinc -mu604800 halfopped. $+ $network $+ . $+ $chan $opnick 1
}
on *:dehalfop:#:{
  kstream $nick $+ : $+ $karma($nick,$network) dehalfopped $nick $+ : $+ $karma($opnick,$network)
  hinc -mu604800 dehalfop. $+ $network $nick 1
  hinc -mu604800 dehalfopped. $+ $network $opnick 1
  hinc -mu604800 dehalfop. $+ $network $+ . $+ $chan  $nick 1
  hinc -mu604800 dehalfopped. $+ $network $+ . $+ $chan $opnick 1
}
on *:voice:#:{
  kstream $nick $+ : $+ $karma($nick,$network) voiced $nick $+ : $+ $karma($vnick,$network)
  hinc -mu604800 voice. $+ $network $nick 1
  hinc -mu604800 voiced. $+ $network $vnick 1
}
on *:devoice:#:{
  kstream $nick $+ : $+ $karma($nick,$network) devoiced $nick $+ : $+ $karma($vnick,$network)
  hinc -mu604800 devoice. $+ $network $nick 1
  hinc -mu604800 devoiced. $+ $network $opnick 1
  hinc -mu604800 devoice. $+ $network $+ . $+ $chan  $nick 1
  hinc -mu604800 devoiced. $+ $network $+ . $+ $chan $vnick 1
}
on ^*:quit:{
  kstream $nick $+ : $+ $karma($nick,$network) quit $network
  hinc -mu604800 quit. $+ $network $nick 1
  if ($chan != $null) {
    hinc -m quit. $+ $network $nick 1
  }
  if ($hget(ig,$network) == 1) && ($karma($nick,$network) < $goodkarma) { halt }
}

on ^*:notice:*:*:{
  kstream $nick $+ $ : $+ $karma($nick,$network) $1-
  hinc -mu604800 notice. $+ $network $nick 1
  if ($nick == nickserv) {
    if ($2 == is) { echonick $hget(ns,target) NickServ: $1- | hadd -mu19000 ns target $1 | hadd -mu19000 ns.name. $+ $network $1 $3- }
    if (registered isin $1) || (registered isin $2) {
      if (year isin $3-) { hadd -m ns.oay $hget(ns,target) 1 }
      if (month isin $3-) { hadd -m ns.oam $hget(ns,target) 1 }
      if ($date(mmm) !isin $2-) && ($date(dd) !isin $2-) {
        hadd -m $network $+ .nsg $hget(ns,target) 1
        echonick $hget(ns,target) $hget(ns,target) is at minimum registered for over a day
      }
    }
  }
}

alias echonick {
  var %a = 1 | var %b = $chan(0)
  while (%a <= %b) {
    if ($1 ison $chan(%a)) { echo -t $chan(%a) $2- }
    inc %a
  }
}

alias modeifgood {
  ;;modeifgood nick chan +o
  if ($hget($network $+ .nsg,$1) != $null) || ($karma($1,$network) >= $goodkarma) {  mode $2 $3 $1  }
}

alias wtp {
  if ($hget(noflood. $+ $network,$1) == $null) {
    msg $1 00,0109[00 We the people 09]15: If you want to change things, you have to be about the things you want to change.
    msg $1  09,0109problems 00::09 suggestions 00::09 problem <problem here in text, or link to webpage> 00::09 suggestion <suggestion text/link here> 00::09 poll <Question here> 
    hadd -mu5 noflood. $+ $network $1 1
  }
}

alias goodkarma {
  hadd -m good karma $1
}

alias ginfo {
  var %total = 0
  var %total = $calc(%total + 0. $+ $calc(%total + 0 + $hget(seen. $+ $2,$1)))
  var %total = $calc(%total + 0 + $hget(ns.name. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(respondsfast. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(msg. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(mode. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(join. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(part. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(quit. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(owner. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(ownered. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(adminned. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(op. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(op. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(opped. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(voice. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(voiced. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deowner. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deownered. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deadmin. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deadminned. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deop. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deopped. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(halfop. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(halfopped. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(devoice. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(devoiced. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(kicked. $+ $2,$1))
  var %t = 0
  if ($hget(ns.name,$1) != $null) { echo -ta $1 nsname: $hget(ns.name,$1) | var %t = $calc(%t + 1) }
  if ($hget(respondsfast. $+ $2,$1) != $null) { echo -ta $1 respondsfast: $hget(respondsfast. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(msg. $+ $2,$1) != $null) { echo -ta $1 msg: $hget(msg. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(seen. $+ $2,$1) != $null) { echo -ta $1 Random Seen: $hget(seen. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(notice. $+ $2,$1) != $null) { echo -ta $1 notice: $hget(notice. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(action. $+ $2,$1) != $null) { echo -ta $1 action: $hget(action. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(join. $+ $2,$1) != $null) { echo -ta $1 join: $hget(join. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(part. $+ $2,$1) != $null) { echo -ta $1 part: $hget(part. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(kick. $+ $2,$1) != $null) { echo -ta $1 kick: $hget(kick. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(kicked. $+ $2,$1) != $null) { echo -ta $1 kicked: $hget(kicked. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(quit. $+ $2,$1) != $null) { echo -ta $1 quit: $hget(quit. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(admin. $+ $2,$1) != $null) { echo -ta $1 admin: $hget(admin. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(deadminned. $+ $2,$1) != $null) { echo -ta $1 deadminned: $hget(deadminned. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(owner. $+ $2,$1) != $null) { echo -ta $1 ownered: $hget(owner. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(deownered. $+ $2,$1) != $null) { echo -ta $1 deownered: $hget(deowner. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(op. $+ $2,$1) != $null) { echo -ta $1 opped: $hget(op. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(deopped. $+ $2,$1) != $null) { echo -ta $1 deopped: $hget(deopped. $+ $2,$1) | var %t = $calc(%t + 1) }
  if ($hget(halfop. $+ $2,$1) != $null) { echo -ta $1 halfopped: $hget(halfop. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(voice. $+ $2,$1) != $null) { echo -ta $1 voiced: $hget(voice. $+ $2,$1) | var %t = $calc(%t + 1)  }
  if ($hget(devoiced. $+ $2,$1) != $null) { echo -ta $1 devoiced: $hget(devoiced. $+ $2,$1) | var %t = $calc(%t + 1)  }
  echo -ta Total: %t
}

alias kstream {
  config.set
  if ($window(@kstream) == $null) { window -e @kstream $chan }
  echo -ti @kstream $1-
}

alias ignorekarma {
  ;;ignorekarma nick network <seconds>
  if ($3 isnum) { var %secs = $3 }
  if ($3 == $null) { var %secs = 604800 }
  hadd -mu $+ %secs ignorekarma. $+ $2 $1 %secs
}

alias karma {
  var %total = 0
  if ($hget(ignorekarma. $+ $2,$1) != $null) || ($hget(ignorekarma. $+ $2,$2) != $null) { return 000 }
  var %total = $calc(%total + 0. $+ $calc(%total + 0 + $hget(seen. $+ $2,$1)))
  var %total = $calc(%total + 0 + $hget(ns.name. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(respondsfast. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(msg. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(mode. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(join. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(part. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(quit. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(owner. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(ownered. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(adminned. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(op. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(op. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(opped. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(voice. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(voiced. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deowner. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deownered. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deadmin. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deadminned. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deop. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(deopped. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(halfop. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(halfopped. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(devoice. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(devoiced. $+ $2,$1))
  var %total = $calc(%total + 0 + $hget(kicked. $+ $2,$1))
  ;if ($hget(setkarma. $+ $2,$1) != $null) { var $total = $calc($hget(setkarma. $+ $2,$1) + 0 + %total) }
  return $calc($calc(%total * 0.01) + $hget(setkarma. $+ $2,$1))
}

alias setkarma { hadd -mu604800 setkarma. $+ $network $1 $2 }
alias seenscan {
  var %a = 1 | var %b = $chan(0)
  while (%a <= %b) {
    seenuserscan $chan(%a)
    inc %a
  }
}

alias seenuserscan {
  var %a = 1 | var %b = $nick($1,0)
  while (%a <= %b) {
    hinc -mu604800 seen. $+ $network $nick($1,%a)
    inc %a
  }
}

alias karmascan { scid -a kscan $1 }
alias kscan {
  if ($karma($1,$network) != $null) { echo -ta Karmascan $network $1 $karma($1,$network) }
}

alias automode {
  if ($1 == $null) {
    if ($hget(amode. $+ $network,$chan) != 1) { echo -ta Automode is off. }
  }
  if ($2 == on) { 
    hadd -m amode. $+ $network $chan $1
    echo -ta Will now set mode $1 on new users with $goodkarma score
  }
  if ($2 == off) { hdel amode. $+ $network $chan | echo -ta Autmode off }
}

alias community {
  var %a = 1 | var %b = $chan(0)
  while (%a <= %b) {
    if ($hget(community. $+ $network,$chan(%a)) != $null) {
      msg $chan(%a) [Community] $hget(community. $+ $network,$chan(%a))
    }
    inc %a | inc %c
  }
}

alias announce {
  if ($me ison $2) {
    hadd -m community. $+ $1 $2 $3-
    echo -ta Set community announcer for $2 on $1 to announce:
    echo -ta $hget(community. $+ $1,$2)
    msg $2 [Community] Set announcement for $1 on $2 $+ : $hget(community. $+ $1,$2)
    .timercommunity.announce 0 259200 scid -a community
  }
}

on *:input:#:{
  if ($hget(lastspoke. $+ $network,$chan) == $null) {
    if ($hget(lastspoke. $+ $network,$chan) != $null) { echo -ta You last spoke $hget(lastspoke. $+ $network,$chan) }
    if ($hget(community. $+ $network,$chan) != $null) {
      echo -ta You have community announcements: $hget(community. $+ $network,$chan)
    }
    if ($hget(greet. $+ $network,$chan) != $null) {
      echo -ta You have an auto greeting for all new users: $hget(greet. $+ $network,$chan)
    }
    if ($hget(webgreet. $+ $network,$chan) != $null) {
      echo -ta You have an auto greeting for web-* users: $hget(webgreet. $+ $network,$chan)
    }
    if ($hget(amode. $+ $network,$chan) != $null) {
      echo -ta You have auto modes set for authentic users joining: $hget(amode. $+ $network,$chan)
    }
    if ($hget(autokb. $+ $network,$chan) != $null) {
      echo -ta You have auto-kickban for users with bad karma: $hget(autokb. $+ $network,$chan)
    }
    if ($hget(botmode. $+ $network,$chan) != $null) {
      echo -ta You have bot mode set for $chan - You will auto reply to some things!
    }
  }
  hadd -mu10800 lastspoke. $+ $network $chan $fulldate
}

menu channel {
  Community
  .$chan Announcements:{
    var %g = $?="Announce $chan community text every 24hours to say:"
    if (%g == $null) {
    var %g = Welcome to $chan $+ ! You are using a nickname that is non-authentic. /nick <nickname> and enjoy your stay. Register your nickname with /msg NickServ register <password> <email> Please remember we do not always answer right away, so stick around for a bit. }
    announce $network $chan %g
  }
  .-
  .Disable $chan Announcements:{
    hdel announce. $+ $network $chan | echo -ta Disabled community announcements for $chan on $network
    .timercommunity. $+ $network $+ . $+ $chan off
  }
  Greetings
  .Greet Web-users:{
    var %g = $?="Greet new web-* users with what message?"
    if (%g == $null) { var %g = Welcome to $chan $+ ! You are using a nickname that is non-authentic. /nick <nickname> and enjoy your stay. Please remember we do not always answer right away, so stick around for a bit. }
    hadd -m webgreet. $+ $network $chan %g
    echo -ta Set greeting for web-* users: %g
  }
  .Greet All New Users (non web):{
    var %g = $?="Greet ALL new users with what message?"
    if (%g == $null) { var %g = Welcome to $chan $+ ! You are using a nickname that is non-authentic. /nick <nickname> and enjoy your stay. Please remember we do not always answer right away, so stick around for a bit. }
    hadd -m greet. $+ $network $chan %g
    echo -ta Set greeting for ALL users: %g
  }
  -
  Auto Modes (Join)
  .Set Auto Mode +o/a/q:{
    automode $?="+o ? +q ? +v ?" on
  }
  .-
  .automode remove:{ automode off }
  .automode status:{ automode }
  -
  Robot Mode
  .botmode on:{ hadd -m botmode. $+ $network $chan 1 | echo -ta Botmode for $chan on }
  .botmode off:{ hdel botmode. $+ $network $chan 1 | echo -ta Botmode for $chan on }
  -
  Karmic Autos
  .Auto Kickban Users (< $+ $goodkarma $+ ) ON:{
    var %k = $?="Minimal karma (anything equal or less is kickbanned)"
    if (%k == $null) { var %k = $goodkarma }
    hadd -m autokb. $+ $network $chan %k
    echo -ta Will kickban everybody who does not match minimal karmic score
  }
  .Auto Kickban Users (< $+ $goodkarma $+ ) OFF:{
    hadd -m autokb. $+ $network $chan %k
    echo -ta Will no longer kickban people.
  }
  -
  Punish Word Phrases
  .Add Auto-Shun Word:{
    var %w = $?="Add wildcard word. Like *ban*me*now*"
    var %asw = $hget(autoshunwords. $+ $network,$chan) 
    if (%w == $null) { echo -tias * Error: Enter word next time! | halt }
    hadd -m autoshunwords. $+ $network $chan %asw %w
  }
  .Remove Auto-Shun Word:{
    var %w = $?="Word to remove, must contain wildcard chars (* and ? etc) "
    var %asw = $hget(autoshunwords. $+ $network,$chan) 
    if (%w == $null) { echo -tias * Error: Enter word next time! | halt }
    if ($asw == $null) { echo -tias * Error: Word didn't exist. No auto shun word list! | halt }
    hadd -m autoshunwords. $+ $network $chan $remove(%w,%asw)
    echo -tias * Will autoshun people who say words: $hget(autoshunwords. $+ $network $chan)
  }
  .Shun Words List:{
    var %w = $hget(autoshunwords. $+ $network $chan)
    if (%w != $null) { echo -tias * Will autoshun people who say words: $hget(autoshunwords. $+ $network $chan) }
    if (%w == $null) { Echo * There are no autoshun words for $chan on $network }
  }
  .Clear Shun Words List:{
    echo -tia * Removed autoshun words for $chan
    hdel autobanwords. $+ $network $chan
  }
  .-
  .Add Auto-Ban Word:{
    var %w = $?="Add wildcard word. Like *ban*me*now*"
    var %asw = $hget(autoshunwords. $+ $network,$chan) 
    if (%w == $null) { echo -tias * Error: Enter word next time! | halt }
    hadd -m autobanwords. $+ $network $chan %asw %w
  }
  .Remove Auto-Ban Word:{
    var %w = $?="Word to remove, must contain wildcard chars (* and ? etc) "
    var %asw = $hget(autobanwords. $+ $network,$chan) 
    if (%w == $null) { echo -tia * Error: Enter word next time! | halt }
    if ($asw == $null) { echo -tia * Error: Word didn't exist. No auto shun word list! | halt }
    hadd -m autobanwords. $+ $network $chan $remove(%w,%asw)
    echo -tias * Will autoban people who say words: $hget(autobanwords. $+ $network $chan)
  }
  .Ban Words List:{
    var %w = $hget(autobanwords. $+ $network $chan)
    if (%w != $null) { echo -tis * Will autoshun people who say words: $hget(autobanwords. $+ $network $chan) }
    if (%w == $null) { Echo * There are no autoshun words for $chan on $network }
  }
  .Clear Ban Words List:{
    echo -tia * Removed autoban words for $chan
    hdel autobanwords. $+ $network $chan
  }
  .-
  .blockwords on:{ hadd -m ignorewords. $+ $network $chan 1 }
  .blockwords off:{ hdel ignorewords. $+ $network $chan }

  -
  Karmic Ignore Stuff (< $+ $goodkarma $+ )
  .Ignore All (< $+ $goodkarma $+ ):{ hadd -m ibk. $+ $network $chan 1 }
  .Unignore All (< $+ $goodkarma $+ ):{ hdel ibk. $+ $network $chan }
  .-
  .Ignore Joins (< $+ $goodkarma $+ ):{ hadd -m ij. $+ $network $chan 1 | echo -tias * Ignoring joins for users with less than $goodkarma }  
  .Unignore Joins (< $+ $goodkarma $+ ):{ hdel ij. $+ $network $chan | echo -tias * Unignoring joins for users with less than $goodkarma - You'll see more joins! }
  .-
  .Global Ignore Quits (< $+ $goodkarma $+ ):{ hadd -m iq $network 1 | echo -tias * Ignoring quits for users with less than $goodkarma }
  .Global Unignore Quits (< $+ $goodkarma $+ ):{ hdel iq $network | echo -tias * Unignoring quits for users with less than $goodkarma }
  .-
  .Ignore Ducks:{ hadd -m ignoreducks. $+ $network $chan 1 }
  .Unignore Ducks:{ hdel ignoreducks. $+ $network $chan }
  .-
  .Ignore No-Good Karma:{ hadd -m ignorebk. $+ $network $chan 1 | echo -tias * Ignoring quits for users with less than $goodkarma }
  .Unignore No-Good Karma:{ hdel ignorebk. $+ $network $chan | echo -tias * Unignoring quits for users with less than $goodkarma }
  -
  Anti Flood
  .Auto Shun Flooders ON:{ hadd -m shunflood. $+ $network $chan 1 | echo -tais Set $channel to shun flooders if theyre new and have no karma }
  .Auto Shun Flooders OFF:{ hdel shunflood. $+ $network $chan | echo -tais Unset $channel to shun flooders if theyre new and have no karma }
  .-
  .Auto Muteban Flooders ON:{ hadd -m banflood. $+ $network $chan 1 | echo -tais Set $channel to mute/ban flooders if theyre new and have no karma }
  .Auto Muteban Flooders OFF:{ hdel banflood. $+ $network $chan | echo -tais Unset $channel to mute/ban flooders if theyre new and have no karma }
  .-
  .Auto Kickban Flooders ON:{ hadd -m kbflood. $+ $network $chan 1 | echo -tais Set $channel to kick ban flooders if theyre new and have no karma }
  .Auto Kickban Flooders OFF:{ hdel kbflood. $+ $network $chan | echo -tais Unset $channel to kick ban flooders if theyre new and have no karma }
  -
  Karmic Channel
  .Channel Emergency Mode:{
    mode $chan +m
    if ($network == freenode) { mode $chan +U }
    automode +v on
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %n = $nick($chan,%a)
      if ($karma(%n,$network) >= $goodkarma) {
        if (%n !isvo $chan) && (%n !isop $chan) && (%n !ishop $chan) { mode $chan +v %n }
        if ($network == freenode) && (/ isin $ial(%n)) && ($karma(%n,$network) > 0) && ($karma(%n,$network) < $goodkarma) { mode $chan +v %n }
      }
      inc %a
    }
  }
  .-
  .Unmoderate after 1h:{ timerunmod. $+ $network $+ . $+ $chan 1 3600 mode $chan -m }
  .Umoderate after 3hours:{ timerunmod. $+ $network $+ . $+ $chan 1 10800 mode $chan -m }
  .Umoderatre after 6hours:{ timerunmod. $+ $network $+ . $+ $chan 1 21600 mode $chan -m }
  .-
  .Owner Users (>= $+ $goodkarma):{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) >= $goodkarma) {
        mode $chan +q %nick
      }
      inc %a
    }
  }
  .-
  .DeOwner Users (< $+ $goodkarma):{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) < $goodkarma) && (%nick !isop $chan) && (%nick ishop $chan) {
        mode $chan -q %nick
      }
      inc %a
    }
  }
  .-
  .Admin Users (>= $+ $goodkarma):{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) >= $goodkarma) {
        mode $chan +a %nick
      }
      inc %a
    }
  }
  .-
  .DeAdmin Users (< $+ $goodkarma):{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) < $goodkarma) && (%nick !isop $chan) && (%nick ishop $chan) {
        mode $chan -a %nick
      }
      inc %a
    }
  }
  .-
  .Op Users (>= $+ $goodkarma):{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) >= $goodkarma) {
        mode $chan +o %nick
      }
      inc %a
    }
  }
  .-
  .DeHOP Users (< $+ $goodkarma $+ ):{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) < $goodkarma) && (%nick !isop $chan) && (%nick ishop $chan) {
        mode $chan -h %nick
      }
      inc %a
    }
  }
  .-
  .HOP Users (>= $+ $goodkarma $+ ):{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) >= $goodkarma) {
        mode $chan +h %nick
      }
      inc %a
    }
  }
  .-
  .DeOP Users (< $+ $goodkarma $+ ):{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) < $goodkarma) && (%nick !isop $chan) && (%nick ishop $chan) {
        mode $chan -v %nick
      }
      inc %a
    }
  }
  .-
  .Voice Users (>= $+ $goodkarma $+ ):{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) < $goodkarma) && (%nick !isop $chan) && (%nick ishop $chan) {
        mode $chan +v %nick
      }
      inc %a
    }
  }
  .Devoice Users (< $+ $goodkarma $+ ):{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) < $goodkarma) && (%nick !isop $chan) && (%nick ishop $chan) {
        mode $chan -v %nick
      }
      inc %a
    }
  }
  Karmic Settings
  .Set Good/Acceptable Karma:{
    var %gk = $goodkarma
    goodkarma $?=" Score? IE: 0.5 - Leave blank for default "
  }
  .Show Good/Acceptable Karma:{ echo -ta Good Karma Score: $goodkarma (Users not matching at minimum are considered non-authentic }
  .-
  .Quick Set All Active Users Karma:{
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %nick = $nick($chan,%a)
      if ($karma(%nick,$network) >= 0.05) && ($karma(%nick,$network) < $goodkarma) {
        echo -ti $chan * Karmic %nick $karma(%nick,$network) -> $calc($karma(%nick,$network) + $goodkarma)
        setkarma $nick($chan,%a) $goodkarma
      }
      inc %a
    }
  }
}
menu nicklist {
  whois:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      whois %n
      inc %a
    }
  }
  invite:{
    var %a = 1
    var %b =  $?="chan"
    while ($gettok($snicks,%a,44) != $null) && (%b != $null) {
      var %n = $gettok($snicks,%a,44)
      invite %n %b
      inc %a
    }
  }
  -
  .operator
  ..owner:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      mode $chan +q %n
      inc %a
    }
  }
  ..deowner:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      mode $chan -q %n
      inc %a
    }
  }
  ..-
  ..admin:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      mode $chan +a %n
      inc %a
    }
  }
  ..deadmin:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      mode $chan -a %n
      inc %a
    }
  }
  ..-
  ..op:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      mode $chan +o %n
      inc %a
    }
  }
  ..deop:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      mode $chan -o %n
      inc %a
    }
  }
  .-
  ..half-op:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      mode $chan +h %n
      inc %a
    }
  }
  ..dehalf-op:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      mode $chan +h %n
      inc %a
    }
  }
  ..-
  ..voice:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      mode $chan +v %n
      inc %a
    }
  }
  ..devoice:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      mode $chan -v %n
      inc %a
    }
  }
  ..-
  ..kick:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      raw -q kick $chan %n :
      inc %a
    }
  }
  ..kick-ban:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      raw -q kick $chan %n : $+ $lf $+ mode $chan +b $address(%n,4)
      inc %a
    }
  }
  ..-
  ..ban:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      raw -q mode $chan +b $address(%n,4)
      inc %a
    }
  }
  -
  .irc-operator
  ..kill:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      kill %n 
      inc %a
    }
  }
  ..gline:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      gline %n 3d 3d gline: network interruption
      inc %a
    }
  }
  ..shun:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      shun %n 1h Shun for 1 hour
      inc %a
    }
  }
  ..-
  ..sajoin:{
    var %a = 1
    var %c = $?="chan"
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      sajoin %n %c
      inc %a
    }
  }
  ..sajoin:{
    var %a = 1
    var %c = $?="chan"
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      sajoin %n %c
      inc %a
    }
  }
  ..sapart:{
    var %a = 1
    var %c = $?="chan"
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      sapart %n %c
      inc %a
    }
  }
  ..-
  ..sakick:{
    var %a = 1
    var %c = $?="reason"
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      sakick $chan %n %c
      inc %a
    }
  }
  ..sakickban:{
    var %a = 1
    var %c = $?="chan"
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan +b $address(%n,4)
      sakick $chan %n %c
      inc %a
    }
  }
  ..-
  ..sa-operator
  ...owner:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan +q %n
      inc %a
    }
  }
  ...deowner:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan -q %n
      inc %a
    }
  }
  ...-
  ...admin:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan +a %n
      inc %a
    }
  }
  ...deadmin:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan -a %n
      inc %a
    }
  }
  ...-
  ...op:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan +o %n
      inc %a
    }
  }
  ...-
  ...deop:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan -o %n
      inc %a
    }
  }
  ...-
  ...half-op:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan +h %n
      inc %a
    }
  }
  ...dehalf-op:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan +h %n
      inc %a
    }
  }
  ...-
  ...voice:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan +v %n
      inc %a
    }
  }
  ...devoice:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      samode $chan -v %n
      inc %a
    }
  }
  -
  Karmic
  ..Karma Scan:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      karmascan %n
      inc %a
    }
  }
  ..-
  ..Known Info:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      ginfo %n $network
      inc %a
    }
  }
  ..-
  ..Show Karma:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      echo -ta Karma for %n on $network $+ : $karma(%n,$network)
      inc %a
    }
  }
  .-
  ..Ignore Karmic:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      hadd -m ignorekarma. $+ $network %n 1
      echo -ta Ignoring karma for %n on $network
      inc %a
    }
  }
  .-
  ..Unignore Karmic:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      .hdel ignorekarma. $+ $network %n
      echo -ta Unignoring karma for %n on $network
      inc %a
    }
  }
  -
  add friend:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      echo -t $chan * Added %n as a friend on %network
      hadd -m friend. $+ $network %n 1
      hadd -m friend %n 1
      hdel friend %n
      writeini friends.ini $network $nick 1
      inc %a
    }
  } 
  delete friend:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      echo -t $chan * Removed %n as a friend on %network
      hdel friend. $+ $network %n
      hdel friend %n
      writeini friends.ini $network $nick 0
      inc %a
    }
  }
  -
  Slap!:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      me slaps %n around a bit with a large trout
      inc %a
    }
  }
}
