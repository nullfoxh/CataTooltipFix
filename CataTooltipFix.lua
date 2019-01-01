	--[[

		CataTooltipFix
			by null
			https://github.com/nullfoxh/
			
			Ported from TBC addon NWTooltipFix.
			For use on Atlantiss Cataclysm.

	]]--
	
	local _G, pairs, tonumber, GetSpellLink, GetTradeSkillInfo, IsControlKeyDown
		= _G, pairs, tonumber, GetSpellLink, GetTradeSkillInfo, IsControlKeyDown

	local find = string.find
	local gsub = string.gsub
	local match = string.match
	local format = string.format

	local itemtips = {
		GameTooltip,
		ShoppingTooltip1,
		ShoppingTooltip2,
		ItemRefTooltip,
	}

	local ItemSubData = {
		-- For instance: Forest Mushroom Cap, item id 4604
		[4604] = { 
			{ "51 health", "300 mana" }, 
			{ "18 sec", "3 min" }, 
		},
		
	}

	local SpellSubData = { 
		-- For instance: Sinister Strike, spell id 1752
		 [1752] = { 
		 	{ "45 Energy", "200 Energy" },  
		 	{ "4 damage", "4000 damage" }, 
		 }, 
	}

	-- Getting auras by name as the tip doesn't hold id. Works as long as english clients are used
	-- Might be possible to reliably get aura ID in cata though
	local AuraSubData = {
		["Stealth"] = { 
			{ "Stealthed.", "Yup, Stealthed indeed!" }, 
		}, 
	}

	local function ReplaceHealing(obj)
		local healing = match(obj:GetText(), "Increases healing done by up to (%d+) and damage done")
		if healing then
			obj:SetText(format("Equip: Increases healing done by spells and effects by up to %s.", healing))
		end
	end

	local function ReplaceOther(obj, subdata)
		for k, v in pairs(subdata) do
			local str, count = gsub(obj:GetText(), v[1], v[2])
			if count > 0 then
				obj:SetText(str)
			end
		end
	end

	local function OnTipSetSpell(tip, tipname)
		if IsControlKeyDown() then return end

		local subdata
		local name, rank = tip:GetSpell()
		local id = GetSpellLink(name, rank)
		id = id and tonumber(id:match("spell:(%d+)"))

		if id then
			subdata = SpellSubData[id]
		end

		if subdata then
			for i = 1, tip:NumLines() do
				local obj = _G[format("%sTextLeft%s", tipname, i)]
				if subdata then
					ReplaceOther(obj, subdata)
				end
			end
		end
	end

	local function OnTipSetAura(self, ...)
		if IsControlKeyDown() then return end

		local title = GameTooltipTextLeft1:GetText()
		local subdata = AuraSubData[title]
		if subdata then
			for i = 1, GameTooltip:NumLines() do
				local obj = _G[format("GameTooltipTextLeft%s", i)]
				ReplaceOther(obj, subdata)
			end
		end
	end

	local function OnTipSetItem(tip, name)
		if IsControlKeyDown() then return end

		local subdata
		local _, link = tip:GetItem()

		if link then
			local id = tonumber(match(link, ":(%w+)"))
			subdata = ItemSubData[id]

			if subdata then
				for i = 1, tip:NumLines() do
					local obj = _G[format("%sTextLeft%s", name, i)]
					ReplaceOther(obj, subdata)
				end
			end
		end
	end

	local function OnSetItemRefTip(link)
		if find(link, "^spell:")then
			OnTipSetSpell(ItemRefTooltip, "ItemRefTooltip")
		else
			OnTipSetItem(ItemRefTooltip, "ItemRefTooltip")
		end
	end

	for i = 1, #itemtips do
		local t = itemtips[i]
		t:HookScript("OnTooltipSetItem", function(self) OnTipSetItem(self, self:GetName()) end)
	end

	GameTooltip:SetScript("OnTooltipSetSpell", function(self) OnTipSetSpell(GameTooltip, "GameTooltip") end)

	hooksecurefunc("SetItemRef", OnSetItemRefTip)

	hooksecurefunc(GameTooltip, "SetUnitAura", OnTipSetAura)
	hooksecurefunc(GameTooltip, "SetUnitBuff", OnTipSetAura)
	hooksecurefunc(GameTooltip, "SetUnitDebuff", OnTipSetAura)

	if AtlasLootTooltip then
		if AtlasLootTooltip.HookScript2 then
			AtlasLootTooltip:HookScript2("OnShow", function(self) OnTipSetItem(self, self:GetName()) end)
		end
	end