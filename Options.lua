local _, Skada = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)
local media = LibStub("LibSharedMedia-3.0")

Skada.resetoptions = { [1] = L["No"], [2] = L["Yes"], [3] = L["Ask"] }

Skada.windowdefaults = {
	name = "Skada",

	barspacing = 0,
	bartexture = "BantoBar",
	barfont = "Expressway",
	barfontflags = "",
	barfontsize = 10,
	barheight = 16,
	barwidth = 240,
	barorientation = 1,
	barcolor = { r = 0.3, g = 0.3, b = 0.8, a = 1 },
	barbgcolor = { r = 0.3, g = 0.3, b = 0.3, a = 0.6 },
	barslocked = false,
	clickthrough = false,

	spellschoolcolors = true,
	classcolorbars = true,
	classcolortext = false,
	classicons = true,
	roleicons = false,
	showself = true,

	buttons = { menu = true, reset = true, report = true, mode = true, segment = true },

	title = { textcolor = { r = 0.9, g = 0.9, b = 0.9, a = 1 }, height = 18, font = "Expressway", barfontsize = 10, fontsize = 10, texture = "Armory", bordercolor = { r = 0, g = 0, b = 0, a = 1 }, bordertexture = "None", borderthickness = 2, color = { r = 0.3, g = 0.3, b = 0.3, a = 1 }, fontflags = "" },
	background = {
		height = 200,
		texture = "Solid",
		bordercolor = { r = 0, g = 0, b = 0, a = 1 },
		bordertexture = "Blizzard Party",
		borderthickness = 1,
		color = { r = 0, g = 0, b = 0, a = 0.8 },
		tile = false,
		tilesize = 0,
	},

	strata = "LOW",
	scale = 1,

	reversegrowth = false,
	modeincombat = "",
	returnaftercombat = false,
	wipemode = "",

	hidden = false,
	enabletitle = true,
	titleset = true,

	set = "current",
	mode = nil,

	display = "bar",
	snapto = true,
	version = 1,
	smoothing = true,

	-- Inline exclusive
	isonnewline = false,
	isusingclasscolors = true,
	height = 30,
	width = 600,
	color = { r = 0.3, g = 0.3, b = 0.3, a = 0.6 },
	isusingelvuiskin = true,
	issolidbackdrop = false,
	fixedbarwidth = false,

	-- Broker exclusive
	textcolor = { r = 0.9, g = 0.9, b = 0.9 },
	useframe = true
}

local windefaultscopy = {}
Skada:tcopy(windefaultscopy, Skada.windowdefaults)

Skada.defaults = {
	profile = {
		version = 1,
		reset = { instance = 1, join = 3, leave = 1 },
		icon = { hide = false, radius = 80, minimapPos = 195 },
		numberformat = 1,
		setformat = 3,
		setnumber = true,
		showranks = true,
		setstokeep = 10,
		tooltips = true,
		tooltippos = "smart",
		tooltiprows = 3,
		informativetooltips = true,
		onlykeepbosses = false,
		tentativecombatstart = false,
		hidesolo = false,
		hidepvp = false,
		hidedisables = true,
		hidecombat = false,
		mergepets = true,
		feed = "",
		showtotals = false,
		autostop = false,
		sortmodesbyusage = true,
		updatefrequency = 0.25,

		modules = {},
		columns = {},
		report = { mode = "Damage", set = "current", channel = "Say", chantype = "preset", number = 10 },
		modulesBlocked = {},

		versions = {},

		windows = { windefaultscopy }
	}
}

-- Adds column configuration options for a mode.
function Skada:AddColumnOptions(mod)
	local db = self.db.profile.columns

	if mod.metadata and mod.metadata.columns then
		local cols = {
			type = "group",
			name = mod:GetName(),
			order = 0,
			inline = true,
			args = {}
		}

		for colname, value in pairs(mod.metadata.columns) do
			local c = mod:GetName() .. "_" .. colname

			-- Set initial value from db if available, otherwise use mod default value.
			if db[c] ~= nil then
				mod.metadata.columns[colname] = db[c]
			end

			-- Add column option.
			local col = {
				type = "toggle",
				name = L[colname] or colname,
				get = function() return mod.metadata.columns[colname] end,
				set = function()
					mod.metadata.columns[colname] = not mod.metadata.columns[colname]
					db[c] = mod.metadata.columns[colname]
					Skada:UpdateDisplay(true)
				end,
			}
			cols.args[c] = col
		end

		Skada.options.args.columns.args[mod:GetName()] = cols
	end
end

function Skada:AddLoadableModuleCheckbox(mod, name, description)
	local new = {
		type = "toggle",
		name = name,
		desc = description,
		order = 1,
	}
	Skada.options.args.modules.args[mod] = new
end

local deletewindow = nil
local newdisplay = "bar"

Skada.options = {
	type = "group",
	name = "Skada",
	plugins = {},
	args = {
		d = {
			type = "description",
			name = L["A damage meter."],
			order = 0,
		},

		windows = {
			type = "group",
			name = L["Windows"],
			order = 1,
			args = {}
		},

		resetoptions = {
			type = "group",
			name = L["Data resets"],
			order = 2,
			args = {

				resetinstance = {
					type = "select",
					name = L["Reset on entering instance"],
					desc = L["Controls if data is reset when you enter an instance."],
					values = function() return Skada.resetoptions end,
					get = function() return Skada.db.profile.reset.instance end,
					set = function(self, opt) Skada.db.profile.reset.instance = opt end,
					order = 30,
				},

				resetjoin = {
					type = "select",
					name = L["Reset on joining a group"],
					desc = L["Controls if data is reset when you join a group."],
					values = function() return Skada.resetoptions end,
					get = function() return Skada.db.profile.reset.join end,
					set = function(self, opt) Skada.db.profile.reset.join = opt end,
					order = 31,
				},

				resetleave = {
					type = "select",
					name = L["Reset on leaving a group"],
					desc = L["Controls if data is reset when you leave a group."],
					values = function() return Skada.resetoptions end,
					get = function() return Skada.db.profile.reset.leave end,
					set = function(self, opt) Skada.db.profile.reset.leave = opt end,
					order = 32,
				},

			}

		},

		tooltips = {
			type = "group",
			name = L["Tooltips"],
			order = 3,
			args = {
				tooltips = {
					type = "toggle",
					name = L["Show tooltips"],
					desc = L["Shows tooltips with extra information in some modes."],
					order = 1,
					get = function() return Skada.db.profile.tooltips end,
					set = function() Skada.db.profile.tooltips = not Skada.db.profile.tooltips end,
				},

				informative = {
					type = "toggle",
					name = L["Informative tooltips"],
					desc = L["Shows subview summaries in the tooltips."],
					order = 2,
					get = function() return Skada.db.profile.informativetooltips end,
					set = function() Skada.db.profile.informativetooltips = not Skada.db.profile.informativetooltips end,
				},

				rows = {
					type = "range",
					name = L["Subview rows"],
					desc = L["The number of rows from each subview to show when using informative tooltips."],
					min = 1,
					max = 10,
					step = 1,
					get = function() return Skada.db.profile.tooltiprows end,
					set = function(self, val) Skada.db.profile.tooltiprows = val end,
					order = 3,
				},

				tooltippos = {
					type = "select",
					name = L["Tooltip position"],
					desc = L["Position of the tooltips."],
					values = { ["default"] = L["Default"], ["topright"] = L["Top right"], ["topleft"] = L["Top left"], ["smart"] = L["Smart"] },
					get = function() return Skada.db.profile.tooltippos end,
					set = function(self, opt) Skada.db.profile.tooltippos = opt end,
					order = 4,
				},
			}
		},

		generaloptions = {
			type = "group",
			name = L["General options"],
			order = 4,
			args = {

				mmbutton = {
					type = "toggle",
					name = L["Show minimap button"],
					desc = L["Toggles showing the minimap button."],
					order = 1,
					get = function() return not Skada.db.profile.icon.hide end,
					set = function()
						Skada.db.profile.icon.hide = not Skada.db.profile.icon.hide
						Skada:RefreshMMButton()
					end,
				},

				mergepets = {
					type = "toggle",
					name = L["Merge pets"],
					desc = L["Merges pets with their owners. Changing this only affects new data."],
					order = 2,
					get = function() return Skada.db.profile.mergepets end,
					set = function() Skada.db.profile.mergepets = not Skada.db.profile.mergepets end,
				},

				showtotals = {
					type = "toggle",
					name = L["Show totals"],
					desc = L["Shows a extra row with a summary in certain modes."],
					order = 3,
					get = function() return Skada.db.profile.showtotals end,
					set = function() Skada.db.profile.showtotals = not Skada.db.profile.showtotals end,
				},

				onlykeepbosses = {
					type = "toggle",
					name = L["Only keep boss fighs"],
					desc = L["Boss fights will be kept with this on, and non-boss fights are discarded."],
					order = 4,
					get = function() return Skada.db.profile.onlykeepbosses end,
					set = function() Skada.db.profile.onlykeepbosses = not Skada.db.profile.onlykeepbosses end,
				},

				hidesolo = {
					type = "toggle",
					name = L["Hide when solo"],
					desc = L["Hides Skada's window when not in a party or raid."],
					order = 5,
					get = function() return Skada.db.profile.hidesolo end,
					set = function()
						Skada.db.profile.hidesolo = not Skada.db.profile.hidesolo
						Skada:ApplySettings()
					end,
				},

				hidepvp = {
					type = "toggle",
					name = L["Hide in PvP"],
					desc = L["Hides Skada's window when in Battlegrounds/Arenas."],
					order = 6,
					get = function() return Skada.db.profile.hidepvp end,
					set = function()
						Skada.db.profile.hidepvp = not Skada.db.profile.hidepvp
						Skada:ApplySettings()
					end,
				},

				hidecombat = {
					type = "toggle",
					name = L["Hide in combat"],
					desc = L["Hides Skada's window when in combat."],
					order = 7,
					get = function() return Skada.db.profile.hidecombat end,
					set = function()
						Skada.db.profile.hidecombat = not Skada.db.profile.hidecombat
						Skada:ApplySettings()
					end,
				},

				disablewhenhidden = {
					type = "toggle",
					name = L["Disable while hidden"],
					desc = L["Skada will not collect any data when automatically hidden."],
					order = 8,
					get = function() return Skada.db.profile.hidedisables end,
					set = function()
						Skada.db.profile.hidedisables = not Skada.db.profile.hidedisables
						Skada:ApplySettings()
					end,
				},

				sortmodesbyusage = {
					type = "toggle",
					name = L["Sort modes by usage"],
					desc = L["The mode list will be sorted to reflect usage instead of alphabetically."],
					order = 12,
					width = "full",
					get = function() return Skada.db.profile.sortmodesbyusage end,
					set = function()
						Skada.db.profile.sortmodesbyusage = not Skada.db.profile.sortmodesbyusage
						Skada:ApplySettings()
					end,
				},

				showranks = {
					type = "toggle",
					name = L["Show rank numbers"],
					desc = L["Shows numbers for relative ranks for modes where it is applicable."],
					order = 9,
					get = function() return Skada.db.profile.showranks end,
					set = function()
						Skada.db.profile.showranks = not Skada.db.profile.showranks
						Skada:ApplySettings()
					end,
				},

				tentativecombatstart = {
					type = "toggle",
					name = L["Aggressive combat detection"],
					desc = L
					["Skada usually uses a very conservative (simple) combat detection scheme that works best in raids. With this option Skada attempts to emulate other damage meters. Useful for running dungeons. Meaningless on boss encounters."],
					order = 10,
					get = function() return Skada.db.profile.tentativecombatstart end,
					set = function() Skada.db.profile.tentativecombatstart = not Skada.db.profile.tentativecombatstart end,
				},

				autostop = {
					type = "toggle",
					name = L["Autostop"],
					desc = L["Autostop description"],
					order = 10,
					get = function() return Skada.db.profile.autostop end,
					set = function() Skada.db.profile.autostop = not Skada.db.profile.autostop end,
				},

				showself = {
					type = "toggle",
					name = L["Always show self"],
					desc = L["Keeps the player shown last even if there is not enough space."],
					order = 11,
					get = function() return Skada.db.profile.showself end,
					set = function()
						Skada.db.profile.showself = not Skada.db.profile.showself
						Skada:ApplySettings()
					end,
				},

				numberformat = {
					type = "select",
					name = L["Number format"],
					desc = L["Controls the way large numbers are displayed."],
					values = function() return { [1] = L["Condensed"], [2] = L["Detailed"] } end,
					get = function() return Skada.db.profile.numberformat end,
					set = function(self, opt) Skada.db.profile.numberformat = opt end,
					order = 13,
				},

				datafeed = {
					type = "select",
					name = L["Data feed"],
					desc = L
					["Choose which data feed to show in the DataBroker view. This requires an LDB display addon, such as Titan Panel."],
					values = function()
						local feeds = {}
						feeds[""] = L["None"]
						for name, func in pairs(Skada:GetFeeds()) do feeds[name] = name end
						return feeds
					end,
					get = function() return Skada.db.profile.feed end,
					set = function(self, feed)
						Skada.db.profile.feed = feed
						if feed ~= "" then Skada:SetFeed(Skada:GetFeeds()[feed]) end
					end,
					order = 14,
				},

				setstokeep = {
					type = "range",
					name = L["Data segments to keep"],
					desc = L["The number of fight segments to keep. Persistent segments are not included in this."],
					min = 0,
					max = 99,
					step = 1,
					get = function() return Skada.db.profile.setstokeep end,
					set = function(self, val) Skada.db.profile.setstokeep = val end,
					order = 15,
				},

				setnumber = {
					type = "toggle",
					name = L["Number set duplicates"],
					desc = L["Append a count to set names with duplicate mob names."],
					order = 16,
					get = function() return Skada.db.profile.setnumber end,
					set = function() Skada.db.profile.setnumber = not Skada.db.profile.setnumber end,
				},

				setformat = {
					type = "select",
					name = L["Set format"],
					desc = L["Controls the way set names are displayed."],
					values = Skada:SetLabelFormats(),
					get = function() return Skada.db.profile.setformat end,
					set = function(self, opt)
						Skada.db.profile.setformat = opt; Skada:ApplySettings();
					end,
					order = 17,
					width = "double",
				},

				updatefrequency = {
					type = "range",
					name = L["Update frequency"],
					desc = L["How often windows are updated. Shorter for faster updates. Increases CPU usage."],
					min = 0.10,
					max = 1,
					step = 0.05,
					get = function() return Skada.db.profile.updatefrequency end,
					set = function(self, opt) Skada.db.profile.updatefrequency = opt end,
					order = 18,
					width = "double",
				}

			}
		},
		columns = {
			type = "group",
			name = L["Columns"],
			order = 5,
			args = {},
		},
		modules = {
			type = "group",
			name = L["Disabled Modules"],
			order = 6,
			get = function(i) return Skada.db.profile.modulesBlocked[i[#i]] end,
			set = function(i, value)
				Skada.db.profile.modulesBlocked[i[#i]] = value; Skada.options.args.modules.args.apply.disabled = false
			end,
			args = {
				desc = {
					type = "description",
					name = L["Tick the modules you want to disable."],
					width = "full",
					order = 0,
				},
				apply = {
					type = "execute",
					name = APPLY,
					width = "full",
					func = ReloadUI,
					confirm = function()
						return L["This change requires a UI reload. Are you sure?"]
					end,
					disabled = true,
					order = 99,
				},
			},
		},
		version_history = {
			type = "group",
			name = L["Version History"],
			order = 7,
			args = {
				description = {
					type = "description",
					name = L["View the version history of Skada."],
					width = "full",
					order = 1,
				},
				show_button = {
					type = "execute",
					name = L["Show Version History"],
					desc = L["Display the version history using the notification system."],
					func = function() Skada:ShowVersionHistory() end,
					width = "full",
					order = 2,
				}
			}
		}
	}
}

local function create_window_button(display_key)
	return {
		type = "input",
		name = L["Enter the name for the window."],
		width = "double",
		set = function(self, val)
			if val and val ~= "" then
				Skada:CreateWindow(val, nil, display_key)
			end
		end,
		order = 2,
	}
end

local function update_create_windows()
	local args = Skada.options.args.windows.args

	-- Remove any existing window creation buttons
	for k in pairs(args) do
		if k:match("^create_") or k == "display_types" then
			args[k] = nil
		end
	end

	for name, display in pairs(Skada.displays) do
		-- Create a group for each display type
		local display_group = {
			type = "group",
			name = display.name,
			order = 0.5,
			inline = true,
			args = {
				-- Add description for this display type
				desc = {
					type = "description",
					name = display.description,
					width = "full",
					order = 1,
				},
				create = create_window_button(name)
			}
		}

		-- Add the group to the options
		args["create_" .. name] = display_group
	end
end

-- Hook into AddDisplaySystem to update window creation buttons when displays are registered
local original_add_display = Skada.AddDisplaySystem
Skada.AddDisplaySystem = function(self, key, mod)
	original_add_display(self, key, mod)
	update_create_windows()
end

-- Initialize the window creation buttons when options are loaded
local original_setup = Skada.OptionsSetup
Skada.OptionsSetup = function()
	original_setup()
	update_create_windows()
end
