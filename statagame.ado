
* ----------------------------------------------------------------------------
* -------------------------------------------------------  get OS ------------
* ----------------------------------------------------------------------------

capture program drop getOS
program define getOS

gl OS = .
gl OS = "MacOSX"            
if "`c(os)'" == "Windows" & "`c(machine_type)'" == "PC (64-bit x86-64)" gl  OS = "Win64"
if "`c(os)'" == "Windows" & "`c(machine_type)'" == "PC (32-bit)"        gl  OS = "Win32"
//di "$OS"

gl current = `"`c(pwd)'"'
di "$current"

gl adopath =  `"`c(sysdir_plus)'"' + "\c\"
cd $adopath

if "$OS" == "Win64"  local pathzip = `"`c(sysdir_plus)'"' + "c\cftp_w64.zip"   // win64
if "$OS" == "Win32"  local pathzip = `"`c(sysdir_plus)'"' + "c\cftp_w32.zip"  // win32
if "$OS" == "MacOSX" local pathzip = `"`c(sysdir_plus)'"' + "c\cftp_osx.zip"  // mac-osc

if "$OS" == "Win64"  local pathzip = `"`c(sysdir_plus)'"' + "c\cftp_w64.zip"  // win64
if "$OS" == "Win32"  local pathzip = `"`c(sysdir_plus)'"' + "c\cftp_w32.zip"  // win32
if "$OS" == "MacOSX" local pathzip = `"`c(sysdir_plus)'"' + "c\cftp_osx.zip"  // mac-osc

unzipfile `pathzip' , replace
cd  $current

gl ftppath =    `"`c(sysdir_plus)'"' + "\c\cftp\" + "cftp"
gl animepath =  `"`c(sysdir_plus)'"' + "\c\" + "computerwar.txt"

end

* ----------------------------------------------------------------------------
* --------------------------------------------------- call ftp ---------------
* ----------------------------------------------------------------------------		
  
capture program drop callftpdir
program define callftpdir

//winexec c:\dropbox\dg2\local\dofiles\w64\lftp -e "set net:timeout 10; ls  /home/guest/ > t.txt; bye" -u guest,password 18.220.63.74 > t.txt
 
winexec $ftppath -e "set net:timeout 10; ls  /home/guest/ > t.txt; bye" -u guest,password 18.220.63.74 > t.txt
 
end

* ----------------------------------------------------------------------------
* --------------------------------------------------- read ftp ---------------
* ----------------------------------------------------------------------------		
  
capture program drop readftpdir
program define readftpdir

capture confirm file t.txt
if _rc != 601 {

preserve				
cap import delimited t.txt, varnames(nonames) clear 

split v1, parse(.) 
rename v12 type
drop if type!="sav"
replace v11 = reverse(v11)
split v11, parse(" ") 
gen s = reverse(v111)
drop v*
 
replace s = s +"." + type
   
gl list = s
local NN = _N
forvalues i = 2(1)`NN' {
gl list = "$list" + " " + s[`i']
}
di "$list"
cap erase t.txt

restore

}

end

* ----------------------------------------------------------------------------
* ----------------------------------------------------- enter name -----------
* ----------------------------------------------------------------------------

capture program drop entername
program define entername

gl name = "`c(username)'"

capture confirm file  default.txt
if _rc != 601 {
cap import delimited default.txt, varnames(nonames) clear 
gl name = v1[2]
}

noisily di as result "currently you are playing as: $name" 
noisily di as result "to change this name type c " 
noisily di _request(myrequest)
		
if "$myrequest"=="c" | "$myrequest"=="C" {
noisily di "what do you want to change your name to?"
noisily di _request(name)
gl name = "$name" + "           "
gl name = substr("$name",1,10)
}

preserve 
clear
set obs 5
cap gen n = ""
keep n
replace n = "$name" in 1
export delimited using "default.txt", replace
restore           

end

* ----------------------------------------------------------------------------
* -------------------------------------------------- upload name -------------
* ----------------------------------------------------------------------------		

capture program drop uploadname
program define uploadname
global oldname = "xw4.sav"
global newname = "xw4"  + rtrim("$name") + ".sav"
di "$oldname"
di "$newname"
 
if $local == 1 cap copy  $oldname $newname
if $local == 1 cap erase $oldname
//if $local == 0 winexec c:\dropbox\dg2\local\dofiles\w64\lftp -e "set net:timeout 10; mv /home/guest/$oldname /home/guest/$newname; bye" -u guest,password 13.59.217.214 > t.txt
if $local == 0 winexec $ftppath -e "set net:timeout 10; mv /home/guest/$oldname /home/guest/$newname; bye" -u guest,password 18.220.63.74 > t.txt

end

/*
gl oldname = "g.sav"
gl newname = "h.sav"
winexec c:\statagame\table2\cftp\uploads64inbox.bat $oldname $newname t.txt
*/

* ----------------------------------------------------------------------------
* ------------------------------------------------------ get names -----------
* ----------------------------------------------------------------------------
* this might as well be part of the score/information section ????? 

capture program drop getnames
program define getnames

clear 
set obs 3

gen names = ""
gen money = 0
	
if $local == 1  gl files : dir "$dir" files "*.sav" 
if $local != 1  callftpdir
if $local != 1  sleep 10000
if $local != 1  readftpdir
if $local != 1  gl files = "$list"
local i = 0
foreach file in $files {
if strpos("`file'","w") == 1 {
  local i = `i' + 1
  di "`file'"
    replace names = "`file'"  in `i'
  } 
 }

replace names = substr(name,3,.)
replace names = reverse(substr(reverse(name),5,.))
di `i'
   
gen mynr = 0
replace mynr = 1 if rtrim(names) == rtrim("$name" )  
gen n = _n
sum n if mynr == 1   
gl mynr = r(mean)
   
end	
		
* ----------------------------------------------------------------------------
* -------------------------------------------------- enter offer -------------
* ----------------------------------------------------------------------------
capture program drop enteroffer
program define enteroffer
	global myrequestL = -1
	while $myrequestL<0 | $myrequestL>10 {
		noisily di rtrim("$name"), "how much do you want to offer, " rtrim(names[$l]) "?"
		noisily di _request(myrequestL)
	}

	global myrequestR = -1
	while $myrequestR<0 | $myrequestR>10 {
		noisily di rtrim("$name"), "how much do you want to offer, " rtrim(names[$r]) "?"
		noisily di _request(myrequestR)
	}
 
end

* ----------------------------------------------------------------------------
* -------------------------------------------------- enter verdict -----------
* ----------------------------------------------------------------------------
capture program drop enterverdict
program define enterverdict

noisily di as result rtrim(names[$d]) " offered " rtrim(names[$l]) " " $oL 
noisily di as result rtrim(names[$d]) " offered " rtrim(names[$r]) " " $oR  
noisily di as result rtrim("$name") ", are you gonna accept or reject your offer?" 
	
	global myrequest = "-1"
	while "$myrequest"!="0" & "$myrequest"!="1" & "$myrequest"!="a" & "$myrequest"!="r" {
		noisily di "type 0 if you reject the offer"
		noisily di "type 1 if you accept the offer"
		noisily di _request(myrequest)
	}

end
	
* ----------------------------------------------------------------------------
* -------------------------------------------------- upload offer ------------
* ----------------------------------------------------------------------------		
capture program drop uploadoffer
program define uploadoffer
global oldname = "z" + "$round" + "ol"                 + "r"                 + ".sav"
global newname =       "$round" + "ol" + "$myrequestL" + "r" + "$myrequestR" + ".sav"
di "$oldname"
di "$newname"

if $local == 1 copy  $oldname $newname
if $local == 1 erase $oldname
if $local == 0 winexec $ftppath -e "set net:timeout 10; mv /home/guest/$oldname /home/guest/$newname; bye" -u guest,password 18.220.63.74 > t.txt

end

* ----------------------------------------------------------------------------
* -------------------------------------------------- upload verdict ----------
* ----------------------------------------------------------------------------	

capture program drop uploadverdictL
program define uploadverdictL
global oldname = "z" + "$round" + "vl"                + ".sav"
global newname =       "$round" + "vl" + "$myrequest" + ".sav"
di "$oldname"
di "$newname"

if $local == 1 copy  $oldname $newname
if $local == 1 erase $oldname
if $local == 0 winexec $ftppath -e "set net:timeout 10; mv /home/guest/$oldname /home/guest/$newname; bye" -u guest,password 18.220.63.74 > t.txt
if $local == 0 sleep 2000	
end


capture program drop uploadverdictR
program define uploadverdictR
global oldname = "z" + "$round" + "vr"                + ".sav"
global newname =       "$round" + "vr" + "$myrequest" + ".sav"
di "$oldname"
di "$newname"

if $local == 1 copy  $oldname $newname
if $local == 1 erase $oldname
if $local == 0 winexec $ftppath -e "set net:timeout 10; mv /home/guest/$oldname /home/guest/$newname; bye" -u guest,password 18.220.63.74 > t.txt
if $local == 0 sleep 2000	

end		

* ----------------------------------------------------------------------------
* -------------------------------------------------- scoreboard --------------
* ----------------------------------------------------------------------------

capture program drop showinfo 
program define showinfo 

qui cap gen scoreinc = 0
qui replace scoreinc = 0
qui cap gen score = 0
qui replace score = 0
qui cap gen actions = ""
qui replace actions = ""
qui cap gen o = 0 
qui replace o = 0
qui cap gen a = 0 
qui replace a = 0
qui cap gen v = 0 
qui replace v = 0

 gl line0 = "  "
 gl line1 = "      "
 gl line2 = "  "
 gl line3 = "  "
 gl line4 = "   "
 
forvalues r = 1(1)6 {
gl round1 = `r' 

gl     d1 = mod(0 + $round1 - 1,3) + 1
gl     l1 = mod(1 + $round1 - 1,3) + 1
gl     r1 = mod(2 + $round1 - 1,3) + 1

//di $d
//di $l 
//di $r

local i = 0
foreach file in $files {
if strpos("`file'","`r'") == 1 {
  local i = `i' + 1                                  
  qui  replace actions = "`file'"  in `i'
} 
}

 if `i' > 0   gl oL = substr(actions[1],4,1)
 if `i' > 0   gl oR = substr(actions[1],6,1)
 if `i' > 0   gl oD = 10 - $oL - $oR
 if `i' > 2   gl vL = substr(actions[2],4,1)
 if `i' > 2   gl vR = substr(actions[3],4,1)
 // di "$oD"
 // di "$oL"
 // di "$oR"
 
  if `i' >= 1 {                                     // o = outcome
 qui replace o = $oD  in $d1
 qui replace o = $oL  in $l1
 qui replace o = $oR  in $r1 
 gl o1 = o[1]
 gl o2 = o[2]
 gl o3 = o[3]
 gl o1 = substr("$o1" + "  ",1,2 )
 gl o2 = substr("$o2" + "  ",1,2 )
 gl o3 = substr("$o3" + "  ",1,2 )

 gl line0 = "$line0" + " round " + "`r'" + "    "
 gl line1 = "$line1" + "$o1" + "          "
// gl line2 = "$line2" + "    |       "
// gl line3 = "$line3" + "   / \      "
 gl line4 = "$line4" + "$o2" + "    " + "$o3" +  "    "
 }
 
 if `i' == 3 {                                              // * a = actual amount
 
 qui replace v = 1    in $d1
 qui replace v = $vL  in $l1
 qui replace v = $vR  in $r1 
 gl v1 = v[1]
 gl v2 = v[2]
 gl v3 = v[3]
 if $v1 == 0 				gl line2 = "$line2" + "    X       "
 if $v1 != 0			 	gl line2 = "$line2" + "    |       "
 if $v2 == 0 & $v3 == 0  	gl line3 = "$line3" + "   X X      "
 if $v2 != 0 & $v3 == 0  	gl line3 = "$line3" + "   / X      "
 if $v2 == 0 & $v3 != 0  	gl line3 = "$line3" + "   X \      "
 if $v2 != 0 & $v3 != 0  	gl line3 = "$line3" + "   / \      "
 
 gl aL = $vL*$oL 
 gl aR = $vR*$oR
 gl aD = (10 - $vL*$oL - $vR*$oR)*($vL+$vR>0)     
 qui replace a = $aD in $d1
 qui replace a = $aL in $l1
 qui replace a = $aR in $r1 
 gl a1 = a[1]
 gl a2 = a[2]
 gl a3 = a[3]
 qui replace score = score + a   
 gl s1 = score[1]
 gl s2 = score[2]
 gl s3 = score[3]
 }
 
}
  
 local name1 = name[1] + "           "
 local name2 = name[2] + "           "
 local name3 = name[3] + "           "
 local name1 = substr("`name1'",1,10)
 local name2 = substr("`name2'",1,10)
 local name3 = substr("`name3'",1,10)
 
 gl name1 = "`name1'"
 gl name2 = "`name2'"
 gl name3 = "`name3'"

animation
	
foreach file in $files {
 if strpos("`file'","xw4") == 1 {
  gl bench = "`file'"
  } 
 }
 
gl bench = reverse(substr(reverse(substr("$bench" ,4,.)),5,.))

di " "

end
 
* ----------------------------------------------------------------------------
* -------------------------------------------------- WAR ---------------------
* ----------------------------------------------------------------------------	
	
capture program drop animation
program define animation

preserve
qui import  delimited "$animepath", clear 
 
set more off

gl t0 = mod($round + $task,3) + 1
if $round<1 gl t0 = 0  

gl j0 = $j
if $p < 21  {
if $t0 == 0 & $j > 45   global j0 = 45                  // cap at 45 
if $t0 == 2				global j0 = mod($j0,13)  + 55   // send2: 55 - 68
if $t0 == 1 			global j0 = mod($j0,17)  + 70   // send1: 70 - 87
if $t0 == 3 			global j0 = mod($j0,13)  + 89   // send3: 89 - 102
}
if $p >= 21 			global j0 = mod(45 - $j0,45)     // walk away: 45 -> 0
if $p >= 21 & $j < 0 	global j0 = 0                   // walk away: 45 -> 0

local j1 = 1 + $j0*8
local j2 = 2 + $j0*8
local j3 = 3 + $j0*8
local j4 = 4 + $j0*8
local j5 = 5 + $j0*8
local j6 = 6 + $j0*8
local j7 = 7 + $j0*8
local j8 = 8 + $j0*8

gl s1 = substr("$s1" + "  "			,1,2 )
gl s2 = substr("$s2" + "  "			,1,2 )
gl s3 = substr("$s3" + "  "			,1,2 )
gl n1 = substr("$name1" + "       "	,1,10)
gl n2 = substr("$name2" + "       "	,1,10)
gl n3 = substr("$name3" + "       "	,1,10)

qui replace v = rtrim(v)

qui replace v = substr(v[`j3'],1,22)  + " {bf:$s1}"  + substr(v[`j3'],26,31)                                           in `j3'
qui replace v = substr(v[`j4'],1,4 )  + " {bf:$n2}"  + substr(v[`j4'],16,35)  + "          {bf:$n3}"                   in `j4'
qui replace v = substr(v[`j7'],1,7 )  + " {bf:$s2}"  + substr(v[`j7'],11,21)  + " {bf:$s3 }" + substr(v[`j7'],35,7)    in `j7'
//qui replace v = substr(v[`j7'],1,7 )  + " {bf:$s2}"  + substr(v[`j7'],11,3)  + "{it:$o2}"    + substr(v[`j7'],15,12)  + "{it:$o3}"    + substr(v[`j7'],28,4 ) + " {bf:$s3}" + substr(v[`j7'],34,7)  in `j7'
//qui replace v = substr(v[`j5'],1,21)  + "{it:$o1}"   + substr(v[`j5'],23,35)                                           in `j5'

if length("$bench")>0 {
qui replace v1 = v1[`j4']  + "           $bench"  in `j4'
qui replace v1 = v1[`j5']  + "                  O"   in `j5'
qui replace v1 = v1[`j6']  + "              \_-.)"  in `j6'
qui replace v1 = v1[`j7']  + "                 /\"  in `j7'
}

sleep 200

cls 
di as txt "  " 
di as txt "$line0"
di as txt "$line1"
di as txt "$line2"
di as txt "$line3"
di as txt "$line4"

di as txt "  " 
di "round: $round"
di " task: $task"

di as txt "                      {bf:$n1}"  
di as txt v1[`j1']
di as txt v1[`j2'] // + "   $n1"
di as txt v1[`j3']
di as txt v1[`j4']
di as txt v1[`j5']
di as txt v1[`j6']
di as txt v1[`j7']

restore

end

* ----------------------------------------------------------------------------
* -------------------------------------------------- player 1 ----------------
* ----------------------------------------------------------------------------

capture program drop statagame
program define statagame

set more off
global     local = 0
//lobal       dir = "c:\statagame\table2"
global    rounds = 6
global        ip = "18.220.63.74"    // could call the website to look for most recent ip

cd $dir 
getOS
entername
uploadname
 
global oldp = 2
global j = -1
global playagain = "Y"

// =============================================================================

while "$playagain"=="Y" | "$playagain"=="y" { 
global oldp = -99
global p = 1

getnames

cap gen score = 0 
cap qui replace score = 0
gl s1 = 0
gl s2 = 0
gl s3 = 0
gl bench = "" 

// -----------------------------------------------------------------------------

while ($p < 21)  {
if $oldp != $p global j = 0
global j = $j + 1

* ---- get info ---------- 
if $local == 1  gl files : dir "$dir" files "*.sav" 
if $local != 1  & mod($j,20) == 0  qui callftpdir
if $local != 1  readftpdir
if $local != 1  gl  files = "$list"

* ---- read info ---------- 
local i = 0
foreach file in $files {
if strpos("`file'","z") == 1 {
  local i = `i' + 1
//  di "`file'"
 } 
}
  
gl     p = 7*3 - `i'
gl round = floor($p/3)
gl     d = mod(0 + $round - 1,3) + 1
gl     l = mod(1 + $round - 1,3) + 1
gl     r = mod(2 + $round - 1,3) + 1
gl  task = mod($p            ,3) + 1
gl  newround = $p - $oldp
gl  oldp = $p 
  
* ---- Show Info ------	
showinfo 

* ---- Make Offers ------	
if $newround != 0 & $task == 1  {
if $mynr == $d {
enteroffer
qui uploadoffer
}
}

* ---- Make VerdictL -------
if $newround != 0 & $task == 2     {
if $mynr == $l {
enterverdict	
qui uploadverdictL
}
}

* ---- Make VerdictR -------
if $newround != 0 & $task == 3     {			
if $mynr == $r {
enterverdict	
qui uploadverdictR
}
}

} 
// ---------------------------------------------------------------------------


sleep 5000
if $local != 1  callftpdir
di "$p"

noisily di "you came in .... "
noisily di "do you want to play again?"
noisily di "type Y if you want to play again"
noisily di _request(playagain)

global p = 0 

} 
// ===========================================================================
end
