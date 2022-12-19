;;/load -rs karmic.mrc

alias config.set {
  ;;karma thjat bot considers good in order to consier them authentic (for modes and stuff)
  var %goodkarma = 0.5
  var %polltime = 5m (add later: time for poll expirery)
  hadd -m good karma %goodkarma
  hadd -m poll time %polltime
}

alias ginfo {
  var %total = $calc($hget(seen. $+ $2,$1) + $hget(ns.name,$1) + $hget(respondsfast. $+ $2,$1) + $hget(msg. $+ $2,$1 + 0.001))
  echo -ta Total score: %total
  echo -ta $1 seen: $hget(seen. $+ $2,$1)
  echo -ta $1 vibes: $hget(vibes. $+ $2,$1)
  echo -ta $1 nsname: $hget(ns.name,$1)
  echo -ta $1 respondsfast: $hget(respondsfast. $+ $2,$1)
  echo -ta $1 msg: $hget(msg. $+ $2,$1)
  echo -ta $1 quit: $hget(quit. $+ $2,$1)
  return $calc(%total * 0.01)
}

alias karma {
  var %total = $calc($hget(seen. $+ $2,$1) + $hget(ns.name,$1) + $hget(respondsfast. $+ $2,$1) + $hget(msg. $+ $2,$1))
  return $calc(%total * 0.01)
}

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

on *:join:#:{
  .timerseenuserscan. $+ $network $+ . $+ $chan 1 $r(300,600) seenuserscan $chan
  if ($nick != $me) {
    if ($hget(amode. $+ $network,$chan) != $null) {
      .timer 1 $r(35,75) { modeifgood $nick $chan $hget(amode. $+ $network,$chan)  }
    }
    hinc -m join. $+ $network $nick 1
    if ($hget(ns.name,$nick) == $null)  {
      .timernsinfo. $+ $network $+ . $+ $nick 1 $r(1,35) .msg nickserv info $nick
    }
  }
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
  msg $2 09,0114[09 Poll Ended 14]00 Total votes: %total [Yes: %yes $+ /No: %no $+ ]
  .hdel pollchan.total. $+ $network $chan
  .hdel pollchan.totalyes. $+ $network $chan
  .hdel pollchan.totalno. $+ $network $chan
  .hdel pollchan. $+ $network $chan
  .timerpoll.* $+ $2 $+ * off
}
on *:text:*:*:{
  if ($hget(pollchan. $+ $network,$chan) != $null) {
    if ($1 == end) {
      if ($2 == poll) { pollchanend $network $chan }
    }
    if ($1 == y) || ($1 == yes) || ($1 == 1) || ($1 == n) || ($1 == no) {
      if ($1 == y) || ($1 == yes) {
        hinc -mu300 pollchan.total. $+ $network $chan 1
        hinc -mu300 pollchan.totalyes. $+ $network $chan 1
        echo -t $chan Vote for yes registered
      }
      if ($1 == n) || ($1 == no) {
        hinc -mu300 pollchan.total. $+ $network $chan 1
        hinc -mu300 pollchan.totalno. $+ $network $chan 1
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
    remove %f
    remove %y
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
    msg $chan 00,01 $+ $nick $+ 14:15 there are $lines(solutions. $+ $network $+  $md5($chan)) solutiions for $lines(problems. $+ $network $+  $md5($chan)) registered problems
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
  if ($chan != $null) {
    hinc -m msg. $+ $network $nick 1
  }
}
on *:action:*:*:{
  if ($hget(lastmsgnick. $+ $network,$chan) != $nick) {
    if ($hget(lastmsg. $+ $network,$chan)  != $null) && ($calc($ctime - $hget(lastmsg. $+ $network,$chan)) <= 2) {
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
  hinc -m mode. $+ $network $nick 1
}

on *:quit:{
  if ($chan != $null) {
    hinc -m quit. $+ $network $nick 1
  }
}

on *:notice:*:*:{
  if ($nick == nickserv) {
    if ($2 == is) { echo -s IS: $1- | hadd -mu19000 ns target $1 | hadd -mu19000 ns.name $1 $2 }
    if (registered isin $1) || (registered isin $2) {
      if (year isin $3-) { hadd -m ns.oay $hget(ns,target) 1 }
      if (month isin $3-) { hadd -m ns.oam $hget(ns,target) 1 }
      if {$date(mmm) !isin $2-) && ($date(dd) !isin $2-) {
        hadd -m $network $+ .nsg $hget(ns,target) 1
        echo -ts $hget(ns,target)  is at minimum registered for over a day
      }
    }
  }
}
alias modeifgood {
  ;;modeifgood nick chan +o
  if ($hget($network $+ .nsg,$1) != $null) || ($karma($1,$network) >= $hget(good,karma)) {  mode $2 $3 $1  }
}
alias wtp {
  msg $1 00,0109[00 We the people 09]15: If you want to change things, you have to be about the things you want to change.
  msg $1  09,0109problems 00::09 suggestions 00::09 problem <problem here in text, or link to webpage> 00::09 suggestion <suggestion text/link here>
}
