;;for f (freenode head of staff), andrewbro, tintle and friends
;;right click channel for options
;;right click nicklist for options
;;Made with love, Shane 2022

alias config.set {
  ;;karma that bot considers good in order to consier them authentic (for modes and stuff)
  ;;edit line below
  var %goodkarma = 0.15
  var %polltime = 5m (add later: time for poll expirery)
  hadd -m good karma %goodkarma
  ;;turn minutes in to seconds
  hadd -m poll time $calc($replace(%polltime,m,* 60))
}

on *:join:#:{
  .timerseenuserscan. $+ $network $+ . $+ $chan 1 $r(300,600) seenuserscan $chan
  hadd -mu300 recentjoin. $+ $network $+ . $+ $chan $+ . $+ $nick $nick 1
  if ($karma($nick,$network) < $hget(good,karma)) { ignorekarma $nick $network 300 }
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
    if ($hget(greet. $+ $network,$chan) != $null) && ($karma($nick,$network) <= $hget(good,karma)) {
      .notice $nick $hget(greet. $+ $network,$chan)
    }
    if ($hget(amode. $+ $network,$chan) != $null) {
      .timer 1 $r(35,75) { modeifgood $nick $chan $hget(amode. $+ $network,$chan)  }
    }
    hinc -m join. $+ $network $nick 1
    if ($hget(ns.name,$nick) == $null) && ($karma($nick,$network) <= $hget(good,karma))  {
      .timernsinfo. $+ $network $+ . $+ $nick 1 $r(1,35) .nsinfo $nick
    }
  }
}
alias nsinfo {
  .ignore NickServ
  .msg Nickserv info $nick
  .timerunig.nickserv 1 5 .ignore -r NickServ
}

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
  .hdel pollchan.total. $+ $network $chan
  .hdel pollchan.totalyes. $+ $network $chan
  .hdel pollchan.totalno. $+ $network $chan
  .hdel pollchan. $+ $network $chan
  .timerpoll.* $+ $2 $+ * off
}

alias botmode {
  if ($me ison $active) && ($1 == on) { hadd -m botmode $chan 1 | echo -ta Bot mode for channel $active is now on }
  if ($me ison $active) && ($1 == off) { hdel botmode $chan 1 | echo -ta Bot mode for channel $active is now off }
}

on *:ban:#:{
  if ($banmask iswm $ial($me)) && ($me isop $chan) || ($me ishop $chan) {
    unbanme $chan
    mode $chan -boqav $banmask $nick $nick $nick $nick $nick
    msg $chan Don't do that.
  }
}

alias unbanme {
  if ($me isop $1) {
    var %a = 1 | var %b = $banlist($chan,0) | var %c = 0
    while (%a <= %b) {
      if ($banlist($chan,%a) iswm $ial($me)) { mode $chan -b+eI $banlist($chan,%a) $banlist($chan,%a) $banlist($chan,%a)  | inc %c }
      inc %a
    }
  }
}


on *:text:*:*:{
  hinc -mu604800 msg. $+ $network $nick 1
  hinc -mu604800 msg. $+ $network $+ . $+ $chan $nick 1
  hinc -mu300 recenttalk. $+ $chan $nick 1
  if ($nick isop $chan) && ($karma($nick,$network) >= $hget(good,karma)) {
    if ($1 == unban) && ($2 != $null) {
      var %a = 1 | var %b = $banlist($chan,0) | var %c = 0
      while (%a <= %b) {
        if ($2 isin $banlist($chan,%a)) || ($ial($banlist($chan,%a) != $null) { mode $chan -b $banlist($chan,%a) | inc %c }
        inc %a
      }
      msg $chan %c bans matching removed
    }
  }
  if ($hget(recenttalk.. $+ $chan,$nick) >= 3) { hinc -mu604800 times.flood. $+ $network $nick 1 }
  if ($hget(botmode. $+ $network,$chan) != $null) && ($karma($nick,$network) >= $hget(good,karma)) {
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
  hinc -mu604800 mode. $+ $network $nick 1
  hinc -m mode. $+ $network $nick 1
}

on *:kick:#:{
  hinc -mu604800 kick. $+ $network $nick 1
  hinc -mu604800 kicked. $+ $network $knick 1
  hinc -mu604800 kick. $+ $network $+ . $+ $chan nick 1
  hinc -mu604800 kicked. $+ $network $+ . $+ $chan $knick 1
}
on *:owner:#:{
  hinc -mu604800 owner. $+ $network $nick 1
  hinc -mu604800 ownered. $+ $network $opnick 1
  hinc -mu604800 owner. $+ $network $+ . $+ $chan $nick 1
  hinc -mu604800 ownered. $+ $network $+ . $+ $chan $opnick 1
}
on *:deowner:#:{
  hinc -mu604800 deowner. $+ $network $nick 1
  hdec -mu604800 deownered. $+ $network $opnick 1
  hinc -mu604800 deowner. $+ $network $+ . $+ $chan $nick 1
  hinc -mu604800 deownered. $+ $network $+ . $+ $chan $opnick 1
}
on *:admin:#:{
  hinc -mu604800 admin. $+ $network $nick 1
  hinc -mu604800 adminned. $+ $network $opnick 1
  hinc -mu604800 admin. $+ $network $+ . $+ $chan $nick 1
  hinc -mu604800 adminned. $+ $network $+ . $+ $chan $nick $opnick 1
}
on *:deadmin:#:{
  hinc -mu604800 deadmin. $+ $network $nick 1
  hinc -mu604800 deadminned. $+ $network $opnick 1
  hinc -mu604800 deadmin. $+ $network $+ . $+ $chan $nick 1
  hdec -mu604800 deadminned. $+ $network $+ . $+ $chan $opnick 1
}
on *:op:#:{
  hinc -mu604800 op. $+ $network $nick 1
  hinc -mu604800 opped. $+ $network $opnick 1
  hinc -mu604800 op. $+ $network $+ . $+ $chan $nick 1
  hinc -mu604800 opped. $+ $network $+ . $+ $chan $opnick 1
}
on *:deop:#:{
  hinc -mu604800 deop. $+ $network $nick 1
  hinc -mu604800 deopped. $+ $network $opnick 1
  hinc -mu604800 deop. $+ . $+ $chan $network $nick 1
  hinc -mu604800 deopped. $+ . $+ $chan $network $opnick 1
}
on *:halfop:#:{
  hinc -mu604800 halfop. $+ $network $nick 1
  hinc -mu604800 halfopped. $+ $network $opnick 1
  hinc -mu604800 halfop. $+ $network $+ . $+ $chan $nick 1
  hinc -mu604800 halfopped. $+ $network $+ . $+ $chan $opnick 1
}
on *:dehalfop:#:{
  hinc -mu604800 dehalfop. $+ $network $nick 1
  hinc -mu604800 dehalfopped. $+ $network $opnick 1
  hinc -mu604800 dehalfop. $+ $network $+ . $+ $chan  $nick 1
  hinc -mu604800 dehalfopped. $+ $network $+ . $+ $chan $opnick 1
}
on *:voice:#:{
  hinc -mu604800 voice. $+ $network $nick 1
  hinc -mu604800 voiced. $+ $network $vnick 1
}
on *:devoice:#:{
  hinc -mu604800 devoice. $+ $network $nick 1
  hinc -mu604800 devoiced. $+ $network $opnick 1
  hinc -mu604800 devoice. $+ $network $+ . $+ $chan  $nick 1
  hinc -mu604800 devoiced. $+ $network $+ . $+ $chan $vnick 1
}
on *:quit:{
  hinc -mu604800 quit. $+ $network $nick 1
  if ($chan != $null) {
    hinc -m quit. $+ $network $nick 1
  }
}

on *:notice:*:*:{
  hinc -mu604800 notice. $+ $network $nick 1
  if ($nick == nickserv) {
    if ($2 == is) { echonick $hget(ns,target) NickServ: $1- | hadd -mu19000 ns target $1 | hadd -mu19000 ns.name. $+ $network $1 $3- }
    if (registered isin $1) || (registered isin $2) {
      if (year isin $3-) { hadd -m ns.oay $hget(ns,target) 1 }
      if (month isin $3-) { hadd -m ns.oam $hget(ns,target) 1 }
      if {$date(mmm) !isin $2-) && ($date(dd) !isin $2-) {
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
  if ($hget($network $+ .nsg,$1) != $null) || ($karma($1,$network) >= $hget(good,karma)) {  mode $2 $3 $1  }
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
  return $calc(%total * 0.009)
}
alias setkarma { hadd -mu604800 msg. $+ $network $1 999 }
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
    echo -ta $hget(amode. $+ $network,$chan)
  }
  if ($2 == on) { 
    hadd -m amode. $+ $network $chan $1
    echo -ta Will now set mode $1 on new users
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
  .Greet Webusers:{
    var %g = $?="Greet new web-* users with what message?"
    if (%g == $null) { var %g = Welcome to $chan $+ ! You are using a nickname that is non-authentic. /nick <nickname> and enjoy your stay. Please remember we do not always answer right away, so stick around for a bit. }
    hadd -m webgreet. $+ $network $chan %g
    echo -ta Set greeting for web-* users: %g
  }
  .Greet All New Users:{
    var %g = $?="Greet ALL new users with what message?"
    if (%g == $null) { var %g = Welcome to $chan $+ ! You are using a nickname that is non-authentic. /nick <nickname> and enjoy your stay. Please remember we do not always answer right away, so stick around for a bit. }
    hadd -m greet. $+ $network $chan %g
    echo -ta Set greeting for ALL users: %g
  }
  -
  Auto Modes (Join)
  .Set Auto Mode:{
    automode $?="+o ? +q ? +v ?" on
  }
  .automode remove:{ automode off }
  .-
  .automode status:{ automode }
  -
  Robot Mode
  .botmode on:{ hadd -m botmode. $+ $network $chan 1 | echo -ta Botmode for $chan on }
  .botmode off:{ hdel botmode. $+ $network $chan 1 | echo -ta Botmode for $chan on }
  -
  Shit List
  .autokb on join (karmic):{
    var %k = $?="Minimal karma (anything equal or less is kickbanned)"
    if (%k == $null) { var %k = $hget(good,karma) }
    hadd -m autokb. $+ $network $chan %k
    echo -ta Will kickban everybody who does not match minimal karmic score
  }
  .autokb off:{
    hadd -m autokb. $+ $network $chan %k
    echo -ta Will no longer kickban people.
  }
  -
  mass-modes:{
    var %m = $?="mode? Example: +o"
    var %k = $?="karma? Example: 0.1, Leave empty for everybody"
    if (%k == $null) { var %k = 0 }
    var %a = 1 | var %b = $nick($chan,0)
    while (%a <= %b) {
      var %n = $nick($chan,%a)
      if ($karma(%n,$network) >= %k) { mode $chan %m %n }
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
  .-
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
  Slap!:{
    var %a = 1
    while ($gettok($snicks,%a,44) != $null) {
      var %n = $gettok($snicks,%a,44)
      me slaps %n around a bit with a large trout
      inc %a
    }
  }
}
