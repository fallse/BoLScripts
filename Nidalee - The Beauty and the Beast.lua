local Version = "1.09"
if myHero.charName ~= "Nidalee" then return end
local IsLoaded = "The Beauty and the Beast"
local AUTOUPDATE = true
---------------------------------------------------------------------
--- AutoUpdate for the script ---------------------------------------
---------------------------------------------------------------------
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_NAME = "Nidalee - The Beauty and the Beast"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/bolqqq/BoLScripts/master/Nidalee%20-%20The%20Beauty%20and%20the%20Beast.lua?chunk="..math.random(1, 1000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#FF99CC\">["..IsLoaded.."]:</font> <font color=\"#FFDFBF\">"..msg..".</font>") end
if AUTOUPDATE then
    local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH)
    if ServerData then
        local ServerVersion = string.match(ServerData, "local Version = \"%d+.%d+\"")
        ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
        if ServerVersion then
            ServerVersion = tonumber(ServerVersion)
            if tonumber(Version) < ServerVersion then
                AutoupdaterMsg("A new version is available: ["..ServerVersion.."]")
                AutoupdaterMsg("The script is updating... please don't press [F9]!")
                DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function ()
				AutoupdaterMsg("Successfully updated! ("..Version.." -> "..ServerVersion.."), Please reload (double [F9]) for the updated version!") end) end, 3)
            else
                AutoupdaterMsg("Your script is already the latest version: ["..ServerVersion.."]")
            end
        end
    else
        AutoupdaterMsg("Error downloading version info!")
    end
end
---------------------------------------------------------------------
--- AutoDownload the required libraries -----------------------------
---------------------------------------------------------------------
local REQUIRED_LIBS = 
	{
		["VPrediction"] = "https://raw.github.com/honda7/BoL/master/Common/VPrediction.lua",
		["Collision"] = "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/master/Common/Collision.lua",
		["Prodiction"] = "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/master/Common/Prodiction.lua"
	}
		
local DOWNLOADING_LIBS = false
local DOWNLOAD_COUNT = 0
local SELF_NAME = GetCurrentEnv() and GetCurrentEnv().FILE_NAME or ""

function AfterDownload()
	DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
	if DOWNLOAD_COUNT == 0 then
		DOWNLOADING_LIBS = false
		print("<font color=\"#FF99CC\">["..IsLoaded.."]:</font><font color=\"#FFDFBF\"> Required libraries downloaded successfully, please reload (double [F9]).</font>")
	end
end

for DOWNLOAD_LIB_NAME, DOWNLOAD_LIB_URL in pairs(REQUIRED_LIBS) do
	if FileExist(LIB_PATH .. DOWNLOAD_LIB_NAME .. ".lua") then
		require(DOWNLOAD_LIB_NAME)
	else
		DOWNLOADING_LIBS = true
		DOWNLOAD_COUNT = DOWNLOAD_COUNT + 1

		print("<font color=\"#FF99CC\">["..IsLoaded.."]:</font><font color=\"#FFDFBF\"> Not all required libraries are installed. Downloading: <b><u><font color=\"#73B9FF\">"..DOWNLOAD_LIB_NAME.."</font></u></b> now! Please don't press [F9]!</font>")
		DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
	end
end

if DOWNLOADING_LIBS then return end
---------------------------------------------------------------------
--- Vars ------------------------------------------------------------
---------------------------------------------------------------------
-- Vars for Ranges --
	local qRange, wRange, eRange = 1500, 900, 600
	local qSpeed, qDelay, qWidth = 1300, 0.125, 60
	local wSpeed, wDelay, wWidth = 1450, 0.500, 80
	local wCRange, eCRange = 375, 375 -- E Range = 400-25 for testing
	local qCRange = myHero.range + GetDistance(myHero.minBBox)
-- Vars for Abilitys --
	local qHname, wHname, eHname, rName = "Javelin Toss", "Bushwhack", "Primal Surge", "Aspect of the Cougar"
	local qCname, wCname, eCname = "Takedown", "Pounce", "Swipe"
	local QREADY, WREADY, EREADY, RREADY
	local ignite = nil
	local qColor = ARGB(153, 178, 255, 0 )
	local wColor = ARGB(255, 38, 201,170)
	local eColor = ARGB(89, 179, 0,128)
-- Vars for VPrediction --
	local VP = nil
-- Vars for PROdiction --
	local qPos = nil
	local OnDashPos = nil
	local AfterDashPos = nil
	local AfterImmobilePos = nil
    local OnImmobilePos = nil
-- Vars for PredictionMode -- 
	local PredictionMode = nil
-- Vars for TargetSelector --
	local ts
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1500, DAMAGE_MAGIC, true)
	ts.name = Nidalee
	local Target = nil
-- Vars for Jump Assistant --
	local minRange = 100
	local displayRange = 1000
	local rotateMultiplier = 12
	local closest = minRange+1
	local startPoint = {}
	local endPoint = {}
	local directionVector = {}
	local directionPos = {}
	local lastUsedStart = {}
	local lastUsedEnd = {}
	local busy = false
	local functionDelay = 0;
	local functionToExecute = nil
-- Vars for Orbwalking --
	local lastAnimation = nil
	local lastAttack = 0
	local lastAttackCD = 0
	local lastWindUpTime = 0
-- Vars for JungleClear --
	local JungleMobs = {}
	local JungleFocusMobs = {}
	local JungleMode
-- Vars for LaneClear --
	local LaneClearModeVar
	local enemyMinions = minionManager(MINION_ENEMY, 1000, player, MINION_SORT_HEALTH_ASC)
-- Vars for Autolevel --
	levelSequence = {
					startQ = { 1,3,1,2,1,4,1,3,1,3,4,3,3,2,2,4,2,2 },
					startW = { 2,3,1,1,1,4,1,3,1,3,4,3,3,2,2,4,2,2 },
					startE = { 3,1,1,2,1,4,1,3,1,3,4,3,3,2,2,4,2,2 },
					hardLane = { 3,1,3,2,3,4,1,1,1,1,4,3,3,2,2,4,2,2 }
					}	
-- Misc Vars --
	local Recalling = false
	local Menu 

---------------------------------------------------------------------
--- Onload Function -------------------------------------------------
---------------------------------------------------------------------
function OnLoad()
	AddMenu()
	IgniteCheck()
	JungleNames()
	VP = VPrediction()
	-- LFC --
	_G.oldDrawCircle = rawget(_G, 'DrawCircle')
	_G.DrawCircle = DrawCircle2
	-- PROdiction -- 
	Prod = ProdictManager.GetInstance()
    ProdQ = Prod:AddProdictionObject(_Q, qRange, qSpeed, qDelay, qWidth)
	-- VIP Prediction --
	qp = TargetPredictionVIP(qRange, qSpeed, qDelay, qWidth)
	-- CallBacks --
     for i = 1, heroManager.iCount do
           local hero = heroManager:GetHero(i)
           if hero.team ~= myHero.team then
              ProdQ:GetPredictionOnDash(hero, OnDashFunc)
              ProdQ:GetPredictionAfterDash(hero, AfterDashFunc)
			  ProdQ:GetPredictionOnImmobile(hero, OnImmobileFunc)
              ProdQ:GetPredictionAfterImmobile(hero, AfterImmobileFunc)
           end
       end
	PrintChat("<font color=\"#eFF99CC\">["..IsLoaded.."]:</font><font color=\"#FFDFBF\"> Sucessfully loaded! Version: [<u><b>"..Version.."</b></u>]</font>")
end
---------------------------------------------------------------------
--- Menu ------------------------------------------------------------
---------------------------------------------------------------------
function AddMenu()
	-- Script Menu --
	Menu = scriptConfig("Nidalee - The Beauty and the Beast", "Nidalee")
	
	-- Target Selector --
	Menu:addTS(ts)
	
	-- Create SubMenu --
	Menu:addSubMenu(""..myHero.charName..": Basic Settings", "Basic")
	Menu:addSubMenu(""..myHero.charName..": Combo Settings", "SBTW")
	Menu:addSubMenu(""..myHero.charName..": KillSteal Settings", "KS")
	Menu:addSubMenu(""..myHero.charName..": Farm Settings", "Farm")
	Menu:addSubMenu(""..myHero.charName..": JungleClear Settings", "Jungle")
	Menu:addSubMenu(""..myHero.charName..": Escape and Jump Settings", "Jump")
	Menu:addSubMenu(""..myHero.charName..": Prediction Settings", "Prediction")
	Menu:addSubMenu(""..myHero.charName..": Drawing Settings", "Draw")
	
	-- Basics -- 
	Menu.Basic:addParam("aimQ", "Throw a predicted Spear: ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	Menu.Basic:addParam("aimQtoggle", "Auto throw a predicted Spear: ", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("U"))
	Menu.Basic:addParam("aimWbehind", "Aim (W) behind the Target: ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	Menu.Basic:addParam("autoHeal", "Auto Heal Toggle: ", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("N"))
	Menu.Basic:addParam("autoHealSlider", "Auto Heal if Health below %: ",  SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
	Menu.Basic:addParam("AutoLevelSkills", "Auto Level Skills (Reload Script!)", SCRIPT_PARAM_LIST, 1, { "No Autolevel", "QEQW - R>Q>E>W", "WEQQ - R>Q>E>W", "EQQW - R>Q>E>W", "EQEWE- R>Q>E>W"})
	
	-- SBTW Combo --
	Menu.SBTW:addParam("sbtwKey", "Combo Key: ", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu.SBTW:addParam("sbtwHQ", "Use "..qHname.." (Q) in Combo", SCRIPT_PARAM_ONOFF, true)
	Menu.SBTW:addParam("sbtwHW", "Use "..wHname.." (W) in Combo", SCRIPT_PARAM_ONOFF, true)
	Menu.SBTW:addParam("sbtwHE", "Use "..eHname.." (E) in Combo", SCRIPT_PARAM_ONOFF, true)
	Menu.SBTW:addParam("sbtwCQ", "Use "..qCname.." (Q) in Combo", SCRIPT_PARAM_ONOFF, true)
	Menu.SBTW:addParam("sbtwCW", "Use "..wCname.." (W) in Combo", SCRIPT_PARAM_ONOFF, true)
	Menu.SBTW:addParam("sbtwCE", "Use "..eCname.." (E) in Combo", SCRIPT_PARAM_ONOFF, true)
	Menu.SBTW:addParam("sbtwR", "Switch Forms (R) in Combo: ", SCRIPT_PARAM_ONOFF, true)
	Menu.SBTW:addParam("sbtwItems", "Use Items in Combo: ", SCRIPT_PARAM_ONOFF, true)
	Menu.SBTW:addParam("sbtwOrb", "OrbWalk in Combo", SCRIPT_PARAM_ONOFF, true)
	Menu.SBTW:addParam("sbtwHealSlider", "Auto Heal if Health below %: ",  SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
	
	-- KillSteal --
--	Menu.KS:addParam("aIgnite", "Use Auto Ignite", SCRIPT_PARAM_ONOFF, true)
	
	-- Lane Clear --
	Menu.Farm:addParam("laneClearTyp", "Form in LaneClear: ", SCRIPT_PARAM_LIST, 3, {"Human", "Cougar", "Mixed"})
	Menu.Farm:addParam("clearLane", "Lane Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
	Menu.Farm:addParam("lastHitMinions", "Auto LastHit Minions with AA's", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
	Menu.Farm:addParam("clearHQ", "Farm with "..qHname.." (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu.Farm:addParam("clearHW", "Farm with "..wHname.." (W)", SCRIPT_PARAM_ONOFF, false)
	Menu.Farm:addParam("clearHE", "Farm with "..eHname.." (E)", SCRIPT_PARAM_ONOFF, false)
	Menu.Farm:addParam("clearCQ", "Farm with "..qCname.." (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu.Farm:addParam("clearCW", "Farm with "..wCname.." (W)", SCRIPT_PARAM_ONOFF, false)
	Menu.Farm:addParam("clearCE", "Farm with "..eCname.." (E)", SCRIPT_PARAM_ONOFF, true)
	Menu.Farm:addParam("clearOrbM", "OrbWalk the Minions", SCRIPT_PARAM_ONOFF, true)
	
	-- Jungle Clear --
	Menu.Jungle:addParam("jungleTyp", "Form in JungleClear: ", SCRIPT_PARAM_LIST, 3, {"Human", "Cougar", "Mixed"})
	Menu.Jungle:addParam("jungleKey", "Jungle Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
--	Menu.Jungle:addParam("jungleSteal", "Jungle Steal Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("I"))
	Menu.Jungle:addParam("jungleHQ", "Clear with "..qHname.." (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu.Jungle:addParam("jungleHW", "Clear with "..wHname.." (W)", SCRIPT_PARAM_ONOFF, false)
	Menu.Jungle:addParam("jungleHE", "Clear with "..eHname.." (E)", SCRIPT_PARAM_ONOFF, false)
	Menu.Jungle:addParam("jungleCQ", "Clear with "..qCname.." (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu.Jungle:addParam("jungleCW", "Clear with "..wCname.." (W)", SCRIPT_PARAM_ONOFF, true)
	Menu.Jungle:addParam("jungleCE", "Clear with "..eCname.." (E)", SCRIPT_PARAM_ONOFF, true)
	Menu.Jungle:addParam("jungleOrbwalk", "OrbWalk the Jungle", SCRIPT_PARAM_ONOFF, true)
	
	-- Jump/Escape --
	Menu.Jump:addParam("Jump", "Jump Assistant", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Z"))
	Menu.Jump:addParam("EscapeKey", "Escape Key: ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Y"))
	Menu.Jump:addParam("m2mjump", "Move to Mouse while Jump Assistant: ", SCRIPT_PARAM_ONOFF, true)
	Menu.Jump:addParam("EscapeUseW", "Use "..wCname.." (W) while escape", SCRIPT_PARAM_ONOFF, true)
	Menu.Jump:addParam("EscapeUseE", "Auto "..eHname.." (E) before escape", SCRIPT_PARAM_ONOFF, true)
	Menu.Jump:addParam("EscapeHealSlider", "Auto Heal if Health below %: ",  SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
	Menu.Jump:addParam("JumpSlider", "Jump Accuracy 1:slow - 15:fast", SCRIPT_PARAM_SLICE, 12, 1, 15, 0)
	
	-- Drawings -- 
	Menu.Draw:addParam("drawQ", "Draw Human Q Range: ", SCRIPT_PARAM_ONOFF, true)
	Menu.Draw:addParam("drawW", "Draw Human W Range: ", SCRIPT_PARAM_ONOFF, true)
	Menu.Draw:addParam("drawE", "Draw Human E Range: ", SCRIPT_PARAM_ONOFF, true)
	Menu.Draw:addParam("drawJumpspots", "Draw Jumpspots while pressing Key: ", SCRIPT_PARAM_ONOFF, true)
	Menu.Draw:addParam("drawPerJumpspots", "Draw Jumpspots always: ", SCRIPT_PARAM_ONOFF, false)
	-- LFC --
	Menu.Draw:addSubMenu("["..myHero.charName.." - LFC Settings]", "LFC")
	Menu.Draw.LFC:addParam("LagFree", "Activate Lag Free Circles", SCRIPT_PARAM_ONOFF, false)
	Menu.Draw.LFC:addParam("CL", "Length before Snapping", SCRIPT_PARAM_SLICE, 350, 75, 2000, 0)
	Menu.Draw.LFC:addParam("CLinfo", "Higher length = Lower FPS Drops", SCRIPT_PARAM_INFO, "")
	
	-- Prediction --
	Menu.Prediction:addParam("PredictionMode", "Spear Prediction: ", SCRIPT_PARAM_LIST, 1, {"VPrediction", "PROdiction", "VIP-Prediction"})
	Menu.Prediction:addParam("QHitChance", "HitChance in VIP-Prediction: ", SCRIPT_PARAM_SLICE, 0.7, 0.1, 1, 2)
	
	-- Other --
	Menu:addParam("Version", "Version", SCRIPT_PARAM_INFO, Version)

	-- PermaShow --
	Menu.Basic:permaShow("aimQtoggle")
	Menu.Basic:permaShow("autoHeal")
	Menu.Farm:permaShow("laneClearTyp")
	Menu.Jungle:permaShow("jungleTyp")
	Menu.Prediction:permaShow("PredictionMode")
end
---------------------------------------------------------------------
--- On Tick ---------------------------------------------------------
---------------------------------------------------------------------
function OnTick()
	ts:update()
	Target = ts.target 
	Check()
	LFCfunc()
	AutoLevelMySkills()
	MyAccurateDelay()

	-- Auto Ignite --
--	if Menu.KS.aIgnite and Target ~= nil then AutoIgnite() end
	-- Lane Clear --
	if Menu.Farm.clearLane then LaneClear() end
	-- Jungle Steal --
	if Menu.Jungle.jungleSteal then checkJungleSteal() end
	-- Last Hit --
	if Menu.Farm.lastHitMinions then lastHit() end
	-- Jungle Clear --
	if Menu.Jungle.jungleKey then JungleClear() end
	-- Escape --
	if Menu.Jump.EscapeKey then Escape() end
	-- Auto Heal --
	if Menu.Basic.autoHeal then UseAutoHeal() end
	-- Jump Assistant --
	if Menu.Jump.Jump then JumpAssistant() end 
	-- SBTW Combo --
	if Menu.SBTW.sbtwKey then SBTW() end
	-- Aim Predicted Q Function --
		if Target ~= nil and Menu.Basic.aimQ
			then AimTheQ() 

		end
	-- Toggle Auto Predicted Q Harass --
		if Target ~=nil and Menu.Basic.aimQtoggle and not Recalling
			then AimTheQ()
		end
	-- Starting Aim W behind Function --
		if Target ~= nil and Menu.Basic.aimWbehind
			then AimTheWbehind() 
		end
end
---------------------------------------------------------------------
--- Function Checks for Spells and Forms ----------------------------
---------------------------------------------------------------------
function Check()
	-- Cooldownchecks for Abilitys and Summoners -- 
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	
	-- Check for minions --
	enemyMinions:update()
	
	-- Checks the PredictionMode --
	setPredictionMode()
	
	-- Checks for PROdiction Target --
	if PredictionMode == 2
		then
			if ValidTarget(Target)
				then ProdQ:GetPredictionCallBack(Target, GetQPos)
			else
				qPos = nil
			end
	 end
	 
	-- Check for VIP-Prediction --
	if PredictionMode == 3
		then 
			if Target ~= nil
				then VipPredTarget = qp:GetPrediction(Target)
			end
	end
	
	-- Form checks for Cougar/Human -- 
	if myHero:GetSpellData(_Q).name == "JavelinToss" 
	or myHero:GetSpellData(_W).name == "Bushwhack"
	or myHero:GetSpellData(_E).name == "PrimalSurge"
		then HUMAN = true COUGAR = false
	end
	if myHero:GetSpellData(_Q).name == "Takedown"
	or myHero:GetSpellData(_W).name == "Pounce"
	or myHero:GetSpellData(_E).name == "Swipe"
		then COUGAR = true HUMAN = false
	end
	-- Check if items are ready -- 
		dfgReady		= (dfgSlot		~= nil and myHero:CanUseSpell(dfgSlot)		== READY) -- Deathfire Grasp
		hxgReady		= (hxgSlot		~= nil and myHero:CanUseSpell(hxgSlot)		== READY) -- Hextech Gunblade
		bwcReady		= (bwcSlot		~= nil and myHero:CanUseSpell(bwcSlot)		== READY) -- Bilgewater Cutlass
		botrkReady		= (botrkSlot	~= nil and myHero:CanUseSpell(botrkSlot)	== READY) -- Blade of the Ruined King
		sheenReady		= (sheenSlot 	~= nil and myHero:CanUseSpell(sheenSlot) 	== READY) -- Sheen
	--	lichbaneReady	= (lichbaneSlot ~= nil and myHero:CanUseSpell(lichSlot) 	== READY) -- Lichbane
		trinityReady	= (trinitySlot 	~= nil and myHero:CanUseSpell(trinitySlot) 	== READY) -- Trinity Force
		lyandrisReady	= (liandrysSlot	~= nil and myHero:CanUseSpell(liandrysSlot) == READY) -- Liandrys 
		tmtReady		= (tmtSlot 		~= nil and myHero:CanUseSpell(tmtSlot)		== READY) -- Tiamat
		hdrReady		= (hdrSlot		~= nil and myHero:CanUseSpell(hdrSlot) 		== READY) -- Hydra
		youReady		= (youSlot		~= nil and myHero:CanUseSpell(youSlot)		== READY) -- Youmuus Ghostblade
	-- Set the slots for item --
		dfgSlot 		= GetInventorySlotItem(3128)
		hxgSlot 		= GetInventorySlotItem(3146)
		bwcSlot 		= GetInventorySlotItem(3144)
		botrkSlot		= GetInventorySlotItem(3153)							
		sheenSlot		= GetInventorySlotItem(3057)
	--	lichbaneSlot	= GetInventorySlotItem(3100)
		trinitySlot		= GetInventorySlotItem(3078)
		liandrysSlot	= GetInventorySlotItem(3151)
		tmtSlot			= GetInventorySlotItem(3077)
		hdrSlot			= GetInventorySlotItem(3074)	
		youSlot			= GetInventorySlotItem(3142)
end
---------------------------------------------------------------------
--- ItemUsage -------------------------------------------------------
---------------------------------------------------------------------
function UseItems()
	if not enemy then enemy = Target end
	if ValidTarget(enemy) then
		if dfgReady		and GetDistance(enemy) <= 750 then CastSpell(dfgSlot, enemy) end
		if hxgReady		and GetDistance(enemy) <= 700 then CastSpell(hxgSlot, enemy) end
		if bwcReady		and GetDistance(enemy) <= 450 then CastSpell(bwcSlot, enemy) end
		if botrkReady	and GetDistance(enemy) <= 450 then CastSpell(botrkSlot, enemy) end
		if tmtReady		and GetDistance(enemy) <= 185 then CastSpell(tmtSlot) end
		if hdrReady 	and GetDistance(enemy) <= 185 then CastSpell(hdrSlot) end
		if youReady		and GetDistance(enemy) <= 185 then CastSpell(youSlot) end -- needs better logic
	end
end
---------------------------------------------------------------------
--- Draw Function ---------------------------------------------------
---------------------------------------------------------------------	
function OnDraw()
-- Draw SpellRanges only when our champ is alive and the spell is ready --
	-- Draw Q --
	if Menu.Draw.drawQ and not myHero.dead then
		if QREADY and Menu.Draw.drawQ then DrawCircle(myHero.x, myHero.y, myHero.z, qRange, qColor) end
	end
	-- Draw W --
	if Menu.Draw.drawW and not myHero.dead then
		if WREADY and Menu.Draw.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, wRange, wColor) end
	end
	-- Draw E --
	if Menu.Draw.drawE and not myHero.dead then
		if EREADY and Menu.Draw.drawE then DrawCircle(myHero.x, myHero.y, myHero.z, eRange, eColor) end
	end
-- Draw Jump Spots --
	if Menu.Jump.Jump and COUGAR and Menu.Draw.drawJumpspots
	or Menu.Draw.drawPerJumpspots
	then
				for i,group in pairs(pouncePosition) do
					
					if (GetDistance(group.pA) < displayRange or GetDistance(group.pB) < displayRange) then
						DrawCircle(group.pA.x, group.pA.y, group.pA.z, minRange, 0xFFFFBF)
						DrawCircle(group.pB.x, group.pB.y, group.pB.z, minRange, 0xFFFFBF)
					end
				end
			end
end
---------------------------------------------------------------------
-- Checks Prediction Mode and set ModeVar ---------------------------
-- 1 = VPrediction, 2 = PROdiction, 3 = VIP-Prediction --------------
---------------------------------------------------------------------
function setPredictionMode()
	PredictionMode = Menu.Prediction.PredictionMode
end
---------------------------------------------------------------------
-- Gets the Hitbox of our Target ------------------------------------
-- Call this function to return the Hitbox of our Target for better
-- calculations e.g. to hit targets further away
---------------------------------------------------------------------
function getHitBoxRadius(target)
        return GetDistance(target, target.minBBox)
end
---------------------------------------------------------------------
--- Cast Functions for Spells with and without Prediciton -----------
---------------------------------------------------------------------
function AimTheQ()
	-- VP --
	if PredictionMode == 1 and HUMAN and QREADY
		then AimTheQVP()
	end
	-- Pro --
	if PredictionMode == 2 and HUMAN and QREADY
		then
			if ValidTarget(Target)
				then ProdQ:GetPredictionCallBack(Target, AimTheQPRO)
			end
	end
	-- VIP-Pre --
	if PredictionMode == 3 and HUMAN and QREADY
		then AimTheQVIP()
	end	
end
-- VPrediction of the Q --
function AimTheQVP()
			local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, qDelay, qWidth, qRange, qSpeed, myHero, true)
			if HitChance >= 2  and GetDistance(Target) <= 1900 and QREADY
			then CastSpell(_Q,CastPosition.x,CastPosition.z)
			end
end
-- VIP-Prediction of the Q --
function AimTheQVIP()
            if VipPredTarget and qp:GetHitChance(Target) > Menu.Prediction.QHitChance
			then
			local coll = Collision(qRange, qSpeed, qDelay, qWidth)
				if not coll:GetMinionCollision(Target, myHero)
					then CastSpell(_Q, VipPredTarget.x, VipPredTarget.z)
				end
			end
end
-- Prodiction of the Q with CallBacks--
	-- Sets our Q-Pos of the Target --
function GetQPos(unit, pos)
	qPos = pos
end
	-- Aims the PROdicted Q --
function AimTheQPRO(unit, pos, spell)
    if (GetDistance(pos) - getHitBoxRadius(unit)/2 < qRange)
	--	if GetDistance(pos) < qRange
		then
        local coll = Collision(qRange, qSpeed, qDelay, qWidth)
            if not coll:GetMinionCollision(pos, myHero)
				then CastSpell(_Q, pos.x, pos.z)
            end
    end
end
	-- Calls the function when an enemy starts to dash (Dash, jump, getting knockbacked) --
function OnDashFunc(unit, pos, spell)
    if (GetDistance(pos) - getHitBoxRadius(unit)/2 < qRange)
 -- if GetDistance(pos) < qRange
		then
        local coll = Collision(qRange, qSpeed, qDelay, qWidth)
            if not coll:GetMinionCollision(pos, myHero)
				then CastSpell(_Q, pos.x, pos.z)
            end
    end
end
	-- Calls the function to hit when an enemy is about to land from a dash (e.g. Tristana W) --
function AfterDashFunc(unit, pos, spell)
	if (GetDistance(pos) - getHitBoxRadius(unit)/2 < qRange)
 -- if GetDistance(pos) < qRange
		then
        local coll = Collision(qRange, qSpeed, qDelay, qWidth)
            if not coll:GetMinionCollision(pos, myHero)
				then CastSpell(_Q, pos.x, pos.z)
            end
    end
end
	-- Calls the function when an enemy is immobile (stunned/surpressed) -- 
function OnImmobileFunc(unit, pos, spell)
	if (GetDistance(pos) - getHitBoxRadius(unit)/2 < qRange)
 -- if GetDistance(pos) < qRange
		then
        local coll = Collision(qRange, qSpeed, qDelay, qWidth)
            if not coll:GetMinionCollision(pos, myHero)
				then CastSpell(_Q, pos.x, pos.z)
            end
    end
end
	-- Calls the function right when an enemys immobile ends --
function AfterImmobileFunc(unit, pos, spell)
-- if GetDistance(pos) < qRange
   if (GetDistance(pos) - getHitBoxRadius(unit)/2 < qRange)
		then
        local coll = Collision(qRange, qSpeed, qDelay, qWidth)
            if not coll:GetMinionCollision(pos, myHero)
				then CastSpell(_Q, pos.x, pos.z)
            end
    end
end
-- Aims W (Trap) at the VPredicted Target --
function AimtheW()
		if HUMAN == true then
			local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(Target, wDelay, wWidth, wRange) 
			if HitChance >= 2 and GetDistance(CastPosition) <= 1200 and WREADY
			then CastSpell(_W, CastPosition.x, CastPosition.z)
            end
        end
end
-- Aims W (Trap) behind the VPredicted Target -- 
function AimTheWbehind()
		if HUMAN == true and GetDistance(Target) <= 900 then
			local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(Target, 0.500, 80, 900)
			if HitChance >= 2 and GetDistance(CastPosition) <= 900 and WREADY
			then local CastBehind = myHero + Vector(CastPosition.x-myHero.x, myHero.y, CastPosition.z-myHero.z):normalized()*(GetDistance(myHero,CastPosition)+100)
			if GetDistance(myHero,CastBehind) <= 900 then CastSpell(_W,CastBehind.x,CastBehind.z) end
            end
        end
end
-- Cougar Q -- 
function CastTheCQ(enemy)
		if not enemy then enemy = Target end
		if (not QREADY or (GetDistance(enemy) > qCRange))
			then return false
		end
		if not attackCast then
			if ValidTarget(enemy) then 
				CastSpell(_Q)
				return true
			end
		end
		return false
end
-- Cougar W --
function CastTheWE(enemy)
		if not enemy then enemy = Target end
		if (not WREADY or (GetDistance(enemy) > eWRange))
			then return false
		end
		if not attackCast then
			if ValidTarget(enemy) then 
				CastSpell(_W)
				return true
			end
		end
		return false
end
-- Cougar E --
function CastTheCE(enemy)
		if not enemy then enemy = Target end
		if (not EREADY or (GetDistance(enemy) > eCRange))
			then return false
		end
		if not attackCast then
			if ValidTarget(enemy) then 
				CastSpell(_E)
				return true
			end
		end
		return false
end
---------------------------------------------------------------------
--- SBTW Combos -----------------------------------------------------
---------------------------------------------------------------------
function SBTW()
		if Menu.SBTW.sbtwOrb then
			if Target ~= nil then
				OrbWalking(Target)
			else
			moveToCursor()
			end
		end
		if ValidTarget(Target)
			then 
				if Menu.SBTW.sbtwItems
						then UseItems(Target)
				end
				if HUMAN and GetDistance(Target) >= wRange
						then sbtwHumanPokeMode()
				end
				if HUMAN and GetDistance(Target) < wRange
						then sbtwHumanPokeAndTrapMode()
				end 
				if HUMAN and Menu.SBTW.sbtwR and GetDistance(Target) < 675
						then sbtwCougar()
				end
				if COUGAR and GetDistance(Target) < 675
						then sbtwCougar()
				end
				if COUGAR and Menu.SBTW.sbtwR and GetDistance(Target) > wRange
						then CastSpell(_R)
				end

	end
end
function sbtwHumanPokeMode()
	if Menu.SBTW.sbtwHQ then AimTheQ() end
	if Menu.SBTW.sbtwHE then UseSelfHeal() end
end
function sbtwHumanPokeAndTrapMode()
		if Menu.SBTW.sbtwHQ then AimTheQ() end
		if Menu.SBTW.sbtwHW then AimTheWbehind() end
		if Menu.SBTW.sbtwHE then UseSelfHeal() end
end
function sbtwCougar()
	if HUMAN == true then CastSpell(_R) end
	if COUGAR == true then
			if Menu.SBTW.sbtwCW and GetDistance(Target) <= 400 then CastSpell(_W, Target.x, Target.z) end
			if Menu.SBTW.sbtwCE and GetDistance(Target) <= 300 then CastTheCE(Target) end
			if Menu.SBTW.sbtwCQ and Target.health < (Target.maxHealth*0.50) then CastTheCQ(Target) end
	end
end
function UseSelfHeal()
	if myHero.health < (myHero.maxHealth *(Menu.SBTW.sbtwHealSlider/100)) and EREADY then
			CastSpell(_E, myHero)
	end
end
function UseAutoHeal()
	if HUMAN and not Menu.SBTW.sbtwKey and not Menu.Jump.EscapeKey and not Recalling
		then
			if myHero.health < (myHero.maxHealth *(Menu.Basic.autoHealSlider/100)) and EREADY then
			CastSpell(_E, myHero)
			end
	end
end
---------------------------------------------------------------------
--- KillSteal Functions ---------------------------------------------
---------------------------------------------------------------------
function AutoIgnite()
---------------------------------------------------------------------------------------------rewrite-----------------------------
---------------------------------------------------------------------------------------------rewrite-----------------------------
---------------------------------------------------------------------------------------------rewrite-----------------------------
---------------------------------------------------------------------------------------------rewrite-----------------------------
---------------------------------------------------------------------------------------------rewrite-----------------------------
end
-- Checks the Summonerspells for ignite (OnLoad) --
function IgniteCheck()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
			ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
			ignite = SUMMONER_2
	end
end
---------------------------------------------------------------------
--- Function for Misc Movement --------------------------------------
---------------------------------------------------------------------
function Escape()
moveToCursor()
	if Menu.Jump.EscapeUseE
		then
			if myHero.health < (myHero.maxHealth *(Menu.Jump.EscapeHealSlider/100)) and HUMAN == true
				then 	CastSpell(_E)
						CastSpell(_R)
			end
			if myHero.health > (myHero.maxHealth *(Menu.Jump.EscapeHealSlider/100)) and HUMAN == true
				then	CastSpell(_R)
			end
	end		
	if HUMAN == true and Menu.Jump.EscapeUseE == false
				then	CastSpell(_R)
	end
	if COUGAR == true and Menu.Jump.EscapeUseW
				then	CastSpell(_W)
	end
end
---------------------------------------------------------------------
--- Functions for Jump Assistant ------------------------------------
---------------------------------------------------------------------
function JumpAssistant()
				-- Move to Mouse while Jump Assistant--
				if (Menu.Jump.Jump and Menu.Jump.m2mjump and busy == false)
					then moveToCursor()
				end
				-- Jump Assistant -- 
				if busy == false and COUGAR and WREADY
					then closest = minRange+1 rotateMultiplier = Menu.Jump.JumpSlider
						for i,group in pairs(pouncePosition)
						do
							if (GetDistance(group.pA) < closest or GetDistance(group.pB) < closest )
								then busy = true
							if (GetDistance(group.pA) < GetDistance(group.pB))
								then
								closest = GetDistance(group.pA)
								startPoint = group.pA
								endPoint = group.pB
							else
								closest = GetDistance(group.pB)
								startPoint = group.pB
								endPoint = group.pA
							end
							end 
						end
						if (busy == true)
							then
								directionVector = Vector(startPoint):__sub(endPoint)
								myHero:HoldPosition()
								Packet('S_MOVE', {x = startPoint.x, y = startPoint.z}):send()
								delay = 0.19
								MyDelayAction(changeDirection1,delay)
						end
				end
end
function changeDirection1()
		myHero:HoldPosition()
		Packet('S_MOVE', {x = startPoint.x+directionVector.x/rotateMultiplier, y = startPoint.z+directionVector.z/rotateMultiplier}):send()
		directionPos = Vector(startPoint)
		directionPos.x = startPoint.x+directionVector.x/rotateMultiplier
		directionPos.y = startPoint.y+directionVector.y/rotateMultiplier
		directionPos.z = startPoint.z+directionVector.z/rotateMultiplier
		delay = 0.06
		MyDelayAction(changeDirection2,delay)
end
function changeDirection2()
	Packet('S_MOVE', {x = startPoint.x, y = startPoint.z}):send()
	delay = 0.070
	MyDelayAction(CastJump,delay)
end
function CastJump()
	CastSpell((_W),endPoint.x, endPoint.z)
	myHero:HoldPosition()
	MyDelayAction(freeFunction,1)
end
function freeFunction()
	busy = false
end
function MyAccurateDelay()
		if (functionToExecute ~= nil and (functionDelay <= os.clock()))
			then
				functionDelay = nil
				functionToExecute()
					if (functionDelay == nil)
						then functionToExecute = nil
					end
		end
end
function MyDelayAction(b,a)
	functionDelay = a+os.clock()
	functionToExecute = b
end
---------------------------------------------------------------------
--- Coordinates for the Jump Assistant ------------------------------
---------------------------------------------------------------------
pouncePosition = 
{
	{
		pA = {x = 6393.7299804688, y = -63.87451171875, z = 8341.7451171875},
		pB = {x = 6612.1625976563, y = 56.018413543701, z = 8574.7412109375}
	},
	{
		pA = {x = 7041.7885742188, y = 0, z = 8810.1787109375},
		pB = {x = 7296.0341796875, y = 55.610824584961, z = 9056.4638671875}
	},
	{
		pA = {x = 4546.0258789063, y = 54.257415771484, z = 2548.966796875},
		pB = {x = 4185.0786132813, y = 109.35539245605, z = 2526.5520019531}
	},
	{
		pA = {x = 2805.4074707031, y = 55.182941436768, z = 6140.130859375},
		pB = {x = 2614.3215332031, y = 60.193073272705, z = 5816.9438476563}
	},
	{
		pA =  {x = 6696.486328125, y = 61.310482025146, z = 5377.4013671875},
		pB = {x = 6868.6918945313, y = 55.616455078125, z = 5698.1455078125}
	},
	{
		pA =  {x = 1677.9854736328, y = 54.923847198486, z = 8319.9345703125},
		pB = {x = 1270.2786865234, y = 50.334892272949, z = 8286.544921875}
	},
	{
		pA =  {x = 2809.3254394531, y = -58.759708404541, z = 10178.6328125},
		pB = {x = 2553.8962402344, y = 53.364395141602, z = 9974.4677734375}
	},
	{
		pA =  {x = 5102.642578125, y = -62.845260620117, z = 10322.375976563},
		pB = {x = 5483, y = 54.5009765625, z = 10427}
	},
	{
		pA =  {x = 6000.2373046875, y = 39.544124603271, z = 11763.544921875},
		pB = {x = 6056.666015625, y = 54.385917663574, z = 11388.752929688}
	},
	{
		pA =  {x = 1742.34375, y = 53.561042785645, z = 7647.1557617188},
		pB = {x = 1884.5321044922, y = 54.930736541748, z = 7995.1459960938}
	},
	{
		pA =  {x = 3319.087890625, y = 55.027889251709, z = 7472.4760742188},
		pB = {x = 3388.0522460938, y = 54.486026763916, z = 7101.2568359375}
	},
	{
		pA =  {x = 3989.9423828125, y = 51.94282913208, z = 7929.3422851563},
		pB = {x = 3671.623046875, y = 53.906265258789, z = 7723.146484375}
	},
	{
		pA =  {x = 4936.8452148438, y = -63.064865112305, z = 10547.737304688},
		pB = {x = 5156.7397460938, y = 52.951190948486, z = 10853.216796875}
	},
	{
		pA =  {x = 5028.1235351563, y = -63.082695007324, z = 10115.602539063},
		pB = {x = 5423, y = 55.15357208252, z = 10127}
	},
	{
		pA =  {x = 6035.4819335938, y = 53.918266296387, z = 10973.666015625},
		pB = {x = 6385.4013671875, y = 54.63500213623, z = 10827.455078125}
	},
	{
		pA =  {x = 4747.0625, y = 41.584358215332, z = 11866.421875},
		pB = {x = 4743.23046875, y = 51.196254730225, z = 11505.842773438}
	},
	{
		pA =  {x = 6749.4487304688, y = 44.903495788574, z = 12980.83984375},
		pB = {x = 6701.4965820313, y = 52.563804626465, z = 12610.278320313}
	},
	{
		pA =  {x = 3114.1865234375, y = -42.718975067139, z = 9420.5078125},
		pB = {x = 2757, y = 53.77322769165, z = 9255}
	},
	{
		pA =  {x = 2786.8354492188, y = 53.645294189453, z = 9547.8935546875},
		pB = {x = 3002.0930175781, y = -53.198081970215, z = 9854.39453125}
	},
	{
		pA =  {x = 3803.9470214844, y = 53.730079650879, z = 7197.9018554688},
		pB = {x = 3664.1088867188, y = 54.18229675293, z = 7543.572265625}
	},
	{
		pA =  {x = 2340.0886230469, y = 60.165466308594, z = 6387.072265625},
		pB = {x = 2695.6096191406, y = 54.339839935303, z = 6374.0634765625}
	},
	{
		pA =  {x = 3249.791015625, y = 55.605854034424, z = 6446.986328125},
		pB = {x = 3157.4558105469, y = 54.080295562744, z = 6791.4458007813}
	},
	{
		pA =  {x = 3823.6242675781, y = 55.420352935791, z = 5923.9130859375},
		pB = {x = 3584.2561035156, y = 55.6123046875, z = 6215.4931640625}
	},
	{
		pA =  {x = 5796.4809570313, y = 51.673671722412, z = 5060.4116210938},
		pB = {x = 5730.3081054688, y = 54.921173095703, z = 5430.1635742188}
	},
	{
		pA =  {x = 6007.3481445313, y = 51.673641204834, z = 4985.3803710938},
		pB = {x = 6388.783203125, y = 51.673400878906, z = 4987}
	},
	{
		pA =  {x = 7040.9892578125, y = 57.192108154297, z = 3964.6728515625},
		pB = {x = 6668.0073242188, y = 51.671356201172, z = 3993.609375}
	},	
	{
		pA =  {x = 7763.541015625, y = 54.872283935547, z = 3294.3481445313},
		pB = {x = 7629.421875, y = 56.908012390137, z = 3648.0581054688}
	},
	{
		pA =  {x = 4705.830078125, y = -62.586814880371, z = 9440.6572265625},
		pB = {x = 4779.9809570313, y = -63.09009552002, z = 9809.9091796875}
	},
	{
		pA =  {x = 4056.7907714844, y = -63.152275085449, z = 10216.12109375},
		pB = {x = 3680.1550292969, y = -63.701038360596, z = 10182.296875}
	},
	{
		pA =  {x = 4470.0883789063, y = 41.59789276123, z = 12000.479492188},
		pB = {x = 4232.9799804688, y = 49.295585632324, z = 11706.015625}
	},
	{
		pA =  {x = 5415.5708007813, y = 40.682685852051, z = 12640.216796875},
		pB = {x = 5564.4409179688, y = 41.373748779297, z = 12985.860351563}
	},
	{
		pA =  {x = 6053.779296875, y = 40.587882995605, z = 12567.381835938},
		pB = {x = 6045.4555664063, y = 41.211364746094, z = 12942.313476563}
	},
	{
		pA =  {x = 4454.66015625, y = 42.799690246582, z = 8057.1313476563},
		pB = {x = 4577.8681640625, y = 53.31339263916, z = 7699.3686523438}
	},
	{
		pA =  {x = 7754.7700195313, y = 52.890430450439, z = 10449.736328125},
		pB = {x = 8096.2885742188, y = 53.66955947876, z = 10288.80078125}
	},
	{
		pA =  {x = 7625.3139648438, y = 55.008113861084, z = 9465.7001953125},
		pB = {x = 7995.986328125, y = 53.530490875244, z = 9398.1982421875}
	},
	{
		pA =  {x = 9767, y = 53.044532775879, z = 8839},
		pB = {x = 9653.1220703125, y = 53.697280883789, z = 9174.7626953125}
	},
	{
		pA =  {x = 10775.653320313, y = 55.35241317749, z = 7612.6943359375},
		pB = {x = 10665.490234375, y = 65.222145080566, z = 7956.310546875}
	},
	{
		pA =  {x = 10398.484375, y = 66.200691223145, z = 8257.8642578125},
		pB = {x = 10176.104492188, y = 64.849853515625, z = 8544.984375}
	},
	{
		pA =  {x = 11198.071289063, y = 67.641044616699, z = 8440.4638671875},
		pB = {x = 11531.436523438, y = 53.454048156738, z = 8611.0087890625}
	},
	{
		pA =  {x = 11686.700195313, y = 55.458232879639, z = 8055.9624023438},
		pB = {x = 11314.19140625, y = 58.438243865967, z = 8005.4946289063}
	},
	{
		pA =  {x = 10707.119140625, y = 55.350387573242, z = 7335.1752929688},
		pB = {x = 10693, y = 54.870254516602, z = 6943}
	},
	{
		pA =  {x = 10395.380859375, y = 54.869094848633, z = 6938.5009765625},
		pB = {x = 10454.955078125, y = 55.308219909668, z = 7316.7041015625}
	},
	{
		pA =  {x = 10358.5859375, y = 54.86909866333, z = 6677.1704101563},
		pB = {x = 10070.067382813, y = 55.294486999512, z = 6434.0815429688}
	},
	{
		pA =  {x = 11161.98828125, y = 53.730766296387, z = 5070.447265625},
		pB = {x = 10783, y = -63.57177734375, z = 4965}
	},
	{
		pA =  {x = 11167.081054688, y = -62.898971557617, z = 4613.9829101563},
		pB = {x = 11501, y = 54.571090698242, z = 4823}
	},
	{
		pA =  {x = 11743.823242188, y = 52.005855560303, z = 4387.4672851563},
		pB = {x = 11379, y = -61.565242767334, z = 4239}
	},
	{
		pA =  {x = 10388.120117188, y = -63.61775970459, z = 4267.1796875},
		pB = {x = 10033.036132813, y = -60.332069396973, z = 4147.1669921875}
	},
	{
		pA =  {x = 8964.7607421875, y = -63.284225463867, z = 4214.3833007813},
		pB = {x = 8569, y = 55.544258117676, z = 4241}
	},
	{
		pA =  {x = 5554.8657226563, y = 51.680099487305, z = 4346.75390625},
		pB = {x = 5414.0634765625, y = 51.611679077148, z = 4695.6860351563}
	},
	{
		pA =  {x = 7311.3393554688, y = 54.153884887695, z = 10553.6015625},
		pB = {x = 6938.5209960938, y = 54.441242218018, z = 10535.8515625}
	},
	{
		pA =  {x = 7669.353515625, y = -64.488967895508, z = 5960.5717773438},
		pB =  {x = 7441.2182617188, y = 54.347793579102, z = 5761.8989257813}
	},
	{
		pA =  {x = 7949.65625, y = 54.276401519775, z = 2647.0490722656},
		pB = {x = 7863.0063476563, y = 55.178623199463, z = 3013.7814941406}
	},
	{
		pA =  {x = 8698.263671875, y = 57.178703308105, z = 3783.1169433594},
		pB = {x = 9041, y = -63.242683410645, z = 3975}
	},
	{
		pA =  {x = 9063, y = 68.192077636719, z = 3401},
		pB = {x = 9275.0751953125, y = -63.257461547852, z = 3712.8935546875}
	},
	{
		pA =  {x = 12064.340820313, y = 54.830627441406, z = 6424.11328125},
		pB = {x = 12267.9375, y = 54.83561706543, z = 6742.9453125}
	},
	{
		pA =  {x = 12797.838867188, y = 58.281986236572, z = 5814.9653320313},
		pB = {x = 12422.740234375, y = 54.815074920654, z = 5860.931640625}
	},
	{
		pA =  {x = 11913.165039063, y = 54.050819396973, z = 5373.34375},
		pB = {x = 11569.1953125, y = 57.787326812744, z = 5211.7143554688}
	},	{
		pA =  {x = 9237.3603515625, y = 67.796775817871, z = 2522.8937988281},
		pB = {x = 9344.2041015625, y = 65.500213623047, z = 2884.958984375}
	},
	{
		pA =  {x = 7324.2783203125, y = 52.594970703125, z = 1461.2199707031},
		pB = {x = 7357.3852539063, y = 54.282878875732, z = 1837.4309082031}
	}
}
---------------------------------------------------------------------
-- Jungle Mob Names -------------------------------------------------
---------------------------------------------------------------------
function JungleNames()
-- JungleMobNames are the names of the smaller Junglemobs --
	JungleMobNames =
{
	-- Blue Side --
		-- Blue Buff --
		["YoungLizard1.1.2"] = true, ["YoungLizard1.1.3"] = true,
		-- Red Buff --
		["YoungLizard4.1.2"] = true, ["YoungLizard4.1.3"] = true,
		-- Wolf Camp --
		["wolf2.1.2"] = true, ["wolf2.1.3"] = true,
		-- Wraith Camp --
		["LesserWraith3.1.2"] = true, ["LesserWraith3.1.3"] = true, ["LesserWraith3.1.4"] = true,
		-- Golem Camp --
		["SmallGolem5.1.1"] = true,
	-- Purple Side --
		-- Blue Buff --
		["YoungLizard7.1.2"] = true, ["YoungLizard7.1.3"] = true,
		-- Red Buff --
		["YoungLizard10.1.2"] = true, ["YoungLizard10.1.3"] = true,
		-- Wolf Camp --
		["wolf8.1.2"] = true, ["wolf8.1.3"] = true,
		-- Wraith Camp --
		["LesserWraith9.1.2"] = true, ["LesserWraith9.1.3"] = true, ["LesserWraith9.1.4"] = true,
		-- Golem Camp --
		["SmallGolem11.1.1"] = true,
}
-- FocusJungleNames are the names of the important/big Junglemobs --
	FocusJungleNames =
{
	-- Blue Side --
		-- Blue Buff --
		["AncientGolem1.1.1"] = true,
		-- Red Buff --
		["LizardElder4.1.1"] = true,
		-- Wolf Camp --
		["GiantWolf2.1.1"] = true,
		-- Wraith Camp --
		["Wraith3.1.1"] = true,		
		-- Golem Camp --
		["Golem5.1.2"] = true,		
		-- Big Wraith --
		["GreatWraith13.1.1"] = true, 
	-- Purple Side --
		-- Blue Buff --
		["AncientGolem7.1.1"] = true,
		-- Red Buff --
		["LizardElder10.1.1"] = true,
		-- Wolf Camp --
		["GiantWolf8.1.1"] = true,
		-- Wraith Camp --
		["Wraith9.1.1"] = true,
		-- Golem Camp --
		["Golem11.1.2"] = true,
		-- Big Wraith --
		["GreatWraith14.1.1"] = true,
	-- Dragon --
		["Dragon6.1.1"] = true,
	-- Baron --
		["Worm12.1.1"] = true,
}
	for i = 0, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object ~= nil then
			if FocusJungleNames[object.name] then
				table.insert(JungleFocusMobs, object)
			elseif JungleMobNames[object.name] then
				table.insert(JungleMobs, object)
			end
		end
	end
end
---------------------------------------------------------------------
--- Jungle Clear with different forms -------------------------------
---------------------------------------------------------------------
function JungleClear()
	setJungleMode()
	JungleMob = GetJungleMob()
		if Menu.Jungle.jungleOrbwalk then
			if JungleMob ~= nil
			then OrbWalking(JungleMob)
			else moveToCursor()
			end
		end
		if JungleMob ~= nil then
			if JungleMode == 1 then JungleClearHuman() end 
			if JungleMode == 2 then JungleClearCougar() end 
			if JungleMode == 3 then JungleClearMixed() end
		end
end

function JungleClearHuman()
	if HUMAN == true then
		if Menu.Jungle.jungleHQ and GetDistance(JungleMob) <= qRange then CastSpell(_Q, JungleMob.x, JungleMob.z) end
		if Menu.Jungle.jungleHW and GetDistance(JungleMob) <= wRange then CastSpell(_W, JungleMob.x, JungleMob.z) end
		if Menu.Jungle.jungleHE then CastSpell(_E) end
	end
end

function JungleClearCougar()
	if COUGAR == true then
		if Menu.Jungle.jungleCQ and GetDistance(JungleMob) <= qCRange then CastTheCQ(JungleMob) end
		if Menu.Jungle.jungleCW and GetDistance(JungleMob) <= wCRange then CastSpell(_W, JungleMob.x, JungleMob.z) end
		if Menu.Jungle.jungleCE and GetDistance(JungleMob) <= eCRange then CastTheCE(JungleMob) end
	else CastSpell (_R) end
end

function JungleClearMixed()
	if HUMAN == true then JungleClearHuman() end
	if HUMAN == true and JungleMode == 3
			then
			if Menu.Jungle.jungleHQ and not Menu.Jungle.jungleHW and not Menu.Jungle.jungleHE and not QREADY then CastSpell(_R) end
			if not Menu.Jungle.jungleHQ and Menu.Jungle.jungleHW and not Menu.Jungle.jungleHE and not WREADY then CastSpell(_R) end
			if not Menu.Jungle.jungleHQ and not Menu.Jungle.jungleHW and Menu.Jungle.jungleHE and not EREADY then CastSpell(_R) end
			if Menu.Jungle.jungleHQ and Menu.Jungle.jungleHW and not Menu.Jungle.jungleHE and not QREADY and not WREADY then CastSpell(_R) end
			if Menu.Jungle.jungleHQ and not Menu.Jungle.jungleHW and Menu.Jungle.jungleHE and not QREADY and not EREADY then CastSpell(_R) end
			if not Menu.Jungle.jungleHQ and Menu.Jungle.jungleHW and Menu.Jungle.jungleHE and not WREADY and not EREADY then CastSpell(_R) end
			if Menu.Jungle.jungleHQ and Menu.Jungle.jungleHW and Menu.Jungle.jungleHE and not QREADY and not WREADY and not EREADY then CastSpell(_R) end
		end					
	if COUGAR == true then JungleClearCougar() end
end

function setJungleMode()
	JungleMode = Menu.Jungle.jungleTyp
end
-- Get Jungle Mob --
function GetJungleMob()
        for _, Mob in pairs(JungleFocusMobs) do
                if ValidTarget(Mob, qRange) then return Mob end
        end
        for _, Mob in pairs(JungleMobs) do
                if ValidTarget(Mob, eCRange) then return Mob end
        end
end
---------------------------------------------------------------------
--- Jungle Steal with Q ---------------------------------------------
---------------------------------------------------------------------

---------------------------------------------------------------------------------------------rewrite ------------------
---------------------------------------------------------------------------------------------rewrite ------------------
---------------------------------------------------------------------------------------------rewrite ------------------
---------------------------------------------------------------------------------------------rewrite ------------------
---------------------------------------------------------------------------------------------rewrite ------------------
---------------------------------------------------------------------------------------------rewrite ------------------
---------------------------------------------------------------------------------------------rewrite ------------------

---------------------------------------------------------------------
-- Object Handling Functions ----------------------------------------
-- Checks for objects that are created and deleted
---------------------------------------------------------------------
function OnCreateObj(obj)
	if obj ~= nil then
		if obj.name:find("TeleportHome.troy") then
			if GetDistance(obj) <= 70 then
				Recalling = true
			end
		end 
		if FocusJungleNames[obj.name] then
			table.insert(JungleFocusMobs, obj)
		elseif JungleMobNames[obj.name] then
            table.insert(JungleMobs, obj)
		end
	end
end
function OnDeleteObj(obj)
if obj ~= nil then
		
		if obj.name:find("TeleportHome.troy") then
			if GetDistance(obj) <= 70 then
				Recalling = false
			end
		end 
		for i, Mob in pairs(JungleMobs) do
			if obj.name == Mob.name then
				table.remove(JungleMobs, i)
			end
		end
		for i, Mob in pairs(JungleFocusMobs) do
			if obj.name == Mob.name then
				table.remove(JungleFocusMobs, i)
			end
		end
	end
end
---------------------------------------------------------------------
-- Recalling Functions ----------------------------------------------
-- Checks if our champion is recalling or not and sets the var Recalling based on that
-- Other functions can check Recalling to not interrupt it
---------------------------------------------------------------------
function OnRecall(hero, channelTimeInMs)
	if hero.networkID == player.networkID then
		Recalling = true
	end
end
function OnAbortRecall(hero)
	if hero.networkID == player.networkID then
		Recalling = false
	end
end
function OnFinishRecall(hero)
	if hero.networkID == player.networkID then
		Recalling = false
	end
end
---------------------------------------------------------------------
--- Orbwalker -------------------------------------------------------
---------------------------------------------------------------------
function OrbWalking(Target)
	if TimeToAttack() and GetDistance(Target) <= myHero.range + GetDistance(myHero.minBBox) then
		myHero:Attack(Target)
    elseif heroCanMove() then
        moveToCursor()
    end
end

function TimeToAttack()
    return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end

function heroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end

function moveToCursor()
	if GetDistance(mousePos) then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
		myHero:MoveTo(moveToPos.x, moveToPos.z)
    end        
end

function OnProcessSpell(object,spell)
	if object == myHero then
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
        end
    end
end
function OnAnimation(unit, animationName)
    	if unit.isMe and lastAnimation ~= animationName then 
			lastAnimation = animationName
			if (animationName == "Crit" or animationName == "Spell1") and not attackCast then
				attackCast = true
			elseif animationName:find("Attack") and attackCast then
				attackCast = false
			end
		end
end
---------------------------------------------------------------------
--- Last Hit Minions ------------------------------------------------
---------------------------------------------------------------------
local nextTick = 0
function lastHit()
	enemyMinions:update()
	if GetTickCount() > nextTick then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end						
	for index, minion in pairs(enemyMinions.objects) do
		if ValidTarget(minion) then
			local aaMinionDmg = getDmg("AD",minion,myHero)
			if minion.health <= aaMinionDmg and GetDistance(minion) <= (myHero.range) and not attackCast and GetTickCount() > nextTick then
				myHero:Attack(minion)
				nextTick = GetTickCount() + 450
			end
		end		 
	end
end
---------------------------------------------------------------------
--- Lane Clear with different forms ---------------------------------
---------------------------------------------------------------------
function LaneClear()
		setLaneClearMode()
		if Menu.Farm.clearLane then
			for _, minion in pairs(enemyMinions.objects) do
				if  ValidTarget(minion)
				then
					if LaneClearModeVar == 1 then
						if Menu.Farm.clearOrbM then OrbWalking(minion) end
						if COUGAR == true then CastSpell(_R) end
						if Menu.Farm.clearHQ and QREADY and GetDistance(minion) <= qRange then CastSpell(_Q, minion.x, minion.z) end
						if Menu.Farm.clearHW and WREADY and GetDistance(minion) <= wRange then CastSpell(_W, minion.x, minion.z) end
						if Menu.Farm.clearHE and EREADY then CastSpell(_E) end
					end
					if LaneClearModeVar == 2 then
						if Menu.Farm.clearOrbM then OrbWalking(minion) end
						if HUMAN == true then CastSpell(_R) end
						if Menu.Farm.clearCQ and QREADY and GetDistance(minion) <= qCRange then CastTheCQ(minion) end
						if Menu.Farm.clearCW and WREADY and GetDistance(minion) <= wCRange then CastSpell(_W, minion.x, minion.z) end
						if Menu.Farm.clearCE and EREADY and GetDistance(minion) <= eCRange then CastTheCE(minion) end
					end
					if LaneClearModeVar == 3 then
						if HUMAN == true then
							if Menu.Farm.clearOrbM then OrbWalking(minion) end
							if Menu.Farm.clearHQ and QREADY and GetDistance(minion) <= qRange then CastSpell(_Q, minion.x, minion.z) end
							if Menu.Farm.clearHW and WREADY and GetDistance(minion) <= wRange then CastSpell(_W, minion.x, minion.z) end
							if Menu.Farm.clearHE and EREADY then CastSpell(_E) end
							if Menu.Farm.clearHQ and not Menu.Farm.clearHW and not Menu.Farm.clearHE and not QREADY then CastSpell(_R) end
							if not Menu.Farm.clearHQ and Menu.Farm.clearHW and not Menu.Farm.clearHE and not WREADY then CastSpell(_R) end
							if not Menu.Farm.clearHQ and not Menu.Farm.clearHW and Menu.Farm.clearHE and not EREADY then CastSpell(_R) end
							if Menu.Farm.clearHQ and Menu.Farm.clearHW and not Menu.Farm.clearHE and not QREADY and not WREADY then CastSpell(_R) end
							if Menu.Farm.clearHQ and not Menu.Farm.clearHW and Menu.Farm.clearHE and not QREADY and not EREADY then CastSpell(_R) end
							if not Menu.Farm.clearHQ and Menu.Farm.clearHW and Menu.Farm.clearHE and not WREADY and not EREADY then CastSpell(_R) end
							if Menu.Farm.clearHQ and Menu.Farm.clearHW and Menu.Farm.clearHE and not QREADY and not WREADY and not EREADY then CastSpell(_R) end
						end
						if COUGAR == true then
							if Menu.Farm.clearOrbM then OrbWalking(minion) end
							if Menu.Farm.clearCQ and QREADY and GetDistance(minion) <= qCRange then CastTheCQ(minion) end
							if Menu.Farm.clearCW and WREADY and GetDistance(minion) <= wCRange then CastSpell(_W, minion.x, minion.z) end
							if Menu.Farm.clearCE and EREADY and GetDistance(minion) <= eCRange then CastTheCE(minion) end
						end
					end	
				else
					if Menu.Farm.clearOrbM then moveToCursor() end
				end
			end
		end
end
function setLaneClearMode()
	LaneClearModeVar = Menu.Farm.laneClearTyp
end
---------------------------------------------------------------------
--- Lag Free Circles ------------------------------------------------
---------------------------------------------------------------------
function LFCfunc()
	if not Menu.Draw.LFC.LagFree then _G.DrawCircle = _G.oldDrawCircle end
	if Menu.Draw.LFC.LagFree then _G.DrawCircle = DrawCircle2 end
end
function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
    radius = radius or 300
  quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
  quality = 2 * math.pi / quality
  radius = radius*.92
    local points = {}
    for theta = 0, 2 * math.pi + quality, quality do
        local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        points[#points + 1] = D3DXVECTOR2(c.x, c.y)
    end
    DrawLines2(points, width or 1, color or 4294967295)
end
function round(num) 
 if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end
function DrawCircle2(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        DrawCircleNextLvl(x, y, z, radius, 1, color, Menu.Draw.LFC.CL) 
    end
end
---------------------------------------------------------------------
--- Autolevel Skills ------------------------------------------------
---------------------------------------------------------------------
function AutoLevelMySkills()
		if Menu.Basic.AutoLevelSkills == 2 then
			autoLevelSetSequence(levelSequence.startQ)
		elseif Menu.Basic.AutoLevelSkills == 3 then
			autoLevelSetSequence(levelSequence.startW)
		elseif Menu.Basic.AutoLevelSkills == 4 then
			autoLevelSetSequence(levelSequence.startE)
		elseif Menu.Basic.AutoLevelSkills == 5 then
			autoLevelSetSequence(levelSequence.hardLane)
		end
end