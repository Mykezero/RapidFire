--[[
    Copyright (c) 2015 - Mykezero

    RapidFire is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    RapidFire is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with RapidFire.  If not, see <http://www.gnu.org/licenses/>.
]]--

--[[
		The goal for this program is to automate ranged attacking in the least
		intrusive way. It should only cast ranged attacks when it is absolutely
		possible. This means no trying to cast when moving and not casting if
		the mob is unattackable. This addon should not have to deal with reloading
		ammo. I've created another addon, fastmag, that will handle this duty.

		The program works based on a timer. This timer ticks every 1 second by
		default, but can be changed to what the user desires by running the
		"/rapidfire delay x" command where x is the ranged attack delay in seconds.
		Every tick, validation occurs to see if we can use ranged attacks and does
		so if possible.
]]--

--[[
		This software would not be possible without the tremendous amount of
		F/OSS projects hosted on FFEvo.net and Windower.net. They provided
		me invaluable insight in using lua to its maximum potential.
]]

--[[
		Commands:
			/rapidfire delay x :
			 		sets the auto-fire delay to fire shots every x seconds.
			/rapidfire auto :
					toggles whether auto-fire should start on addon load.
			/rapidfire start :
					starts auto-firing a ranged weapon.
			/rapidfire stop
					stops auto-firing a ranged weapon.
]]

_addon.author   = 'Mykezero'
_addon.name     = 'RapidFire'
_addon.version  = '0.1'

require 'ffxi/target'
require 'common'
require 'powerargs'
require 'timer'

--------------------------------------------------------------------------------
-- desc: Holds the settings that is serialized and deserialized
--------------------------------------------------------------------------------
local RapidFire =
{
	-- wait between attacks.
	Delay = 1,
	-- should we check mob's claim status. used for newer zones where
	-- players can attack claimed mobs.
	IsClaimCheckEnabled = true,
	-- should start the addon on load.
	AutoStart = false
}

--------------------------------------------------------------------------------
-- func : Start
-- desc : Makes the addon start firing shots.
--------------------------------------------------------------------------------
function Start()
	-- Fire one round immediately and ...
	Fire()
	-- the rest on every delay interval
	timer.Create("timer", RapidFire.Delay, -1, Fire)
end

--------------------------------------------------------------------------------
-- func : Stop
-- desc : Makes the addon stop firing shots
--------------------------------------------------------------------------------
function Stop()
	timer.Stop("timer")
end

--------------------------------------------------------------------------------
-- func : BoolToYesNo
-- params:
	-- value : A boolean value to transform
-- desc : Transforms boolean values to "yes" or "no"
-- retn : Returns "Yes" for true and "No" for false
--------------------------------------------------------------------------------
function BoolToYesNo(value)
	return value and ("Yes" or "No")
end

--------------------------------------------------------------------------------
-- func : PrintHelp
-- desc : Prints the help menu for the addon.
--------------------------------------------------------------------------------
function PrintHelp()
	print "[RapidFire] Available Options"
	print "[RapidFire] Start : Begin auto-attacking. "
	print "[RapidFire] Stop : End auto-attacking. "
	print "[RapidFire] Auto : Toggle auto-attacking on load. "
	print "[RapidFire] Delay X : Sets the auto-attack delay time as x seconds. "
end

--------------------------------------------------------------------------------
-- func : Fire()
-- desc : Fires a shot at the target only when possible.
--------------------------------------------------------------------------------
function Fire()
  -- Get our current target.
	local target = get_target('t')

	-- No target
	if(not target) then return end

	-- Get the player.
	local player = get_target('me')

  -- No player found.
	if(not player) then return end

	-- Not attackable
	if(target.Type ~= 2) then return end

	-- Using sqrt here since ashita outputs values like
	-- 25 for a distance of 5
	if(math.sqrt(target.Distance) >= 25) then return end

	-- Filter out claim mobs unless the user
	-- has explicitly set not to do so.
	if(RapidFire.IsClaimCheckEnabled and target.ClaimID ~= 0) then
		if(not IsPartyClaimed(target)) then return end
		if(target.ClaimID ~= player.ServerID) then return end
	end

	-- Add code to detect player moving
		--  Position difference code.
	AshitaCore:GetChatManager():ParseCommand("/ra <t>", CommandInputType.Typed)

	-- Add code to launch attack only if player can see target.
		-- Heading error code.
end

--------------------------------------------------------------------------------
-- func : IsMoving
-- params:
	-- unit : The entity to tell if it has moved.
-- desc : Determines whether an entity has moved from its last location.
-- retn : True if the unit has moved, false otherwise.
--------------------------------------------------------------------------------
function IsMoving(current, last)
	return last.X ~= current.X or last.Y ~= current.Y or last.Z ~= current.Z
end

--------------------------------------------------------------------------------
-- func : IsPartyClaimed
-- params:
	-- unit : An entity to compare claimID's against.
-- desc : Determines whether party member has claim on the given unit.
-- retn : True when a party member has claimed the unit, false otherwise
--------------------------------------------------------------------------------
function IsPartyClaimed(unit)
	-- Loop through all 18 party and alliance members and ...
	for i = 0, 18 do
		-- Compare their ids against the unit's claimid to
		-- see if one of them has claim.
		local memberID = AshitaCore:GetDataManager():GetParty():GetPartyMemberID(i);
		if(unit.ClaimID == memberID) then return true end
	end
	return false
end

--------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
--------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
		local args = cmd:GetArgs()
		local arg_info = PowerArgs(args)

		-- We've recieved a command!
		if(arg_info.has_command) then

			-- Command is not ours to handle.
			if(arg_info.command ~= "/rapidfire") then return false end

			-- Display usage info on command with no parameters
			if(not arg_info.has_parameters) then
				PrintHelp()
				return true
			end

			-- Get the first option: start, stop, auto, ammo or pouch.
			local option = string.lower(arg_info.parameters[1]);

			-- Handle all 1 argument commands.
			if (arg_info.parameter_count == 1) then

				-- User wants addon to start.
				if (option == "start") then Start()

				-- User wants addon to stop.
				elseif (option == "stop") then Stop()

				-- User wants addon to start on addon load.
				elseif (option == "auto") then

					-- toggle the autostart value from true to false and vice versa.
					RapidFire.AutoStart = not RapidFire.AutoStart
					local message = RapidFire.AutoStart and "enabled" or "disabled"
					print(string.format("[RapidFire] Auto-fire now %s to start on addon load. ", message))

				-- An unhandled command was issued.
				else
					print("[RapidFire] Command not recognized. ")
					PrintHelp()
				end

				return true;
			end

			if(arg_info.parameter_count == 2) then
				-- Read in the argument.
				local value = arg_info.parameters[2]
				-- Get the delay value or "nil"
				local delay = (option == "delay") and value or nil

				-- Check if we've properly recieved the delay.
				if(delay == value) then
					-- Save the delay value
					RapidFire.Delay = value
					print(string.format("[RapidFire] Auto-fire will now trigger every %s seconds. ", value))
				else
					print ("[RapidFire] " .. value .. " not found.")
					return true
				end
			end
		end

		-- Default: let other addons handle the command.
		return false
end)

--------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
--------------------------------------------------------------------------------
ashita.register_event('load', function()
		RapidFire = settings:load(_addon.path .. 'settings/rapidfire.json') or RapidFire;
		if(RapidFire.AutoStart) then Start() end
end );

--------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
--------------------------------------------------------------------------------
ashita.register_event('unload', function()
		settings:save(_addon.path .. 'settings/rapidfire.json', RapidFire);
end );
