-- Strict widget fixture: writes to native frames and native quest actions fail tests.
frames, messages, loadedRequests = {}, {}, {}
local methods = {}
local function widget(kind, name, parent)
    local f = {kind=kind, name=name, parent=parent, shown=true, width=100, height=100,
        scale=1, level=1, strata="MEDIUM", scripts={}, events={}}
    setmetatable(f, {__index=function(_, key)
        local fn = methods[key]
        if not fn and key:match("^[A-Z]") then error("Unmodelled widget API: " .. key) end
        return fn
    end})
    frames[#frames+1] = f
    if name then _G[name] = f end
    return f
end
local function writable(f) assert(not rawget(f,"foreign"), "Attempt to mutate native frame") end
function methods:SetSize(w,h) writable(self); self.width,self.height=w,h end
function methods:SetWidth(w) writable(self); self.width=w end
function methods:SetHeight(h) writable(self); self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) writable(self); self.point={...} end
function methods:ClearAllPoints() writable(self); self.point=nil end
function methods:SetAllPoints() writable(self) end
function methods:SetScale(s) writable(self); self.scale=s end
function methods:GetEffectiveScale() return self.scale end
function methods:GetRect() return rawget(self,"left") or 0,rawget(self,"bottom") or 0,self.width,self.height end
function methods:SetFrameStrata(s) writable(self); self.strata=s end
function methods:GetFrameStrata() return self.strata end
function methods:SetFrameLevel(n) writable(self); self.level=n end
function methods:GetFrameLevel() return self.level end
function methods:SetText(t) writable(self); self.text=t end
function methods:SetTextColor(...) writable(self) end
function methods:SetColorTexture(...) writable(self) end
function methods:SetJustifyH(...) writable(self) end
function methods:SetJustifyV(...) writable(self) end
function methods:SetHighlightTexture(...) writable(self) end
function methods:SetClampedToScreen(...) writable(self) end
function methods:SetClipsChildren(...) writable(self) end
function methods:EnableMouse(...) writable(self) end
function methods:EnableKeyboard(...) writable(self) end
function methods:SetPropagateKeyboardInput(...) writable(self) end
function methods:EnableGamePadButton(...) writable(self) end
function methods:EnableGamePadStick(...) writable(self) end
function methods:SetScript(event, fn) writable(self); self.scripts[event]=fn end
function methods:RegisterEvent(event) writable(self); self.events[event]=true end
function methods:UnregisterEvent(event) writable(self); self.events[event]=nil end
function methods:CreateTexture(name) writable(self); return widget("Texture",name,self) end
function methods:CreateFontString(name) writable(self); return widget("FontString",name,self) end
function methods:IsShown() return self.shown end
function methods:Show() writable(self); self.shown=true end
function methods:Hide()
    writable(self); local old=self.shown; self.shown=false
    if old and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:SetShown(show) if show then self:Show() else self:Hide() end end
function methods:Click() if self.scripts.OnClick then self.scripts.OnClick(self) end end
function methods:SetOwner(owner) writable(self); self.owner=owner end
function methods:IsOwned(owner) return rawget(self,"owner")==owner end
function methods:ClearLines() writable(self); self.lines={} end
function methods:AddLine(line) writable(self); self.lines[#self.lines+1]=line end
function CreateFrame(kind,name,parent) assert(not parent or parent==UIParent or not rawget(parent,"foreign")); return widget(kind,name,parent) end
UIParent=widget("Frame","UIParent"); UIParent.width=1920;UIParent.height=1080;UIParent.foreign=true
WorldMapFrame=widget("Frame","WorldMapFrame");WorldMapFrame.foreign=true
local canvas=widget("Frame");canvas.width=1000;canvas.height=700;canvas.foreign=true
local container=widget("Frame");container.width=1000;container.height=700;container.foreign=true
WorldMapFrame.GetMapID=function() return currentMap end
WorldMapFrame.GetCanvas=function() return canvas end
WorldMapFrame.GetCanvasContainer=function() return container end
Minimap=widget("Frame","Minimap");Minimap.width=200;Minimap.height=200;Minimap.foreign=true
GameTooltip=setmetatable({}, {__index=function() error("Native tooltip accessed") end})
local function forbidden() error("Native action or binding mutation") end
AcceptQuest=forbidden;CompleteQuest=forbidden;GetQuestReward=forbidden
SetBinding=forbidden;SetOverrideBinding=forbidden;SetOverrideBindingClick=forbidden
SlashCmdList={}
clock,combat,currentMap=0,false,1
function print(text) messages[#messages+1]=text end
function GetTime() return clock end
function InCombatLockdown() return combat end
function GetLocale() return "koKR" end
function GetBuildInfo() return "1.16.0","test" end
function GetBindingText(button) return button end
function GetQuestGreenRange() return 10 end
function UnitLevel() return 20 end
function UnitClass() return "Mage","MAGE",8 end
function UnitRace() return "Human","Human",1 end
function UnitFactionGroup() return "Alliance" end
function GetProfessions() return 1 end
function GetProfessionInfo() return "Alchemy",nil,100,300,0,0,171 end
function GetPlayerFacing() return 0 end
function GetCVar() return "0" end
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
function issecretvalue(v) return type(v)=="table" and rawget(v,"secret")==true end
questLog,completed,pois,waypoints={}, {}, {}, {}
C_QuestLog={
    GetNumQuestLogEntries=function() return #questLog end,
    GetInfo=function(i) return questLog[i] end,
    GetAllCompletedQuestIDs=function() return completed end,
    IsComplete=function(id) for _,q in ipairs(questLog) do if q.questID==id then return q.ready end end end,
    GetTitleForQuestID=function(id) return "Quest "..id end,
    RequestLoadQuestByID=function(id) loadedRequests[id]=(loadedRequests[id] or 0)+1 end,
    GetQuestDifficultyLevel=function() return 18 end,
    GetNextWaypoint=function(id) if waypoints[id] then return unpack(waypoints[id]) end end,
    GetQuestsOnMap=function(id) return pois[id] or {} end,
    GetQuestObjectives=function() return {{text="Targets 1/3",finished=false}} end,
}
C_Map={
    GetBestMapForUnit=function() return 1 end,
    GetMapInfo=function(id) return {name="Map "..id,parentMapID=id==1 and 10 or 0} end,
    GetMapRectOnMap=function(a,b) if a==1 and b==10 then return 0.2,0.6,0.1,0.5 end end,
    GetWorldPosFromMapPos=function(id,v) if id==1 then return 1,v end end,
    GetMapPosFromWorldPos=function(instance,v,id) return id,v end,
    GetPlayerMapPosition=function() return CreateVector2D(0.5,0.5) end,
    GetMapWorldSize=function() return 1000,1000 end,
}
C_Minimap={GetViewRadius=function() return 100 end}
function emit(event,...)
    for _,f in ipairs(frames) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f,event,...) end end
end
function tick(delta)
    clock=clock+delta
    local count=#frames
    for i=1,count do local f=frames[i]; if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f,delta) end end
end
