-- A popup over the current screen with the music and sound-effect volume sliders.
-- Tapping outside the panel closes it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local UI = script.Parent.Parent
local Theme = require(UI.Theme)
local AudioSettings = require(UI.Parent.Audio.AudioSettings)
local Components = UI.Components
local Label = require(Components.Label)
local IconButton = require(Components.IconButton)
local InkButton = require(Components.InkButton)
local Slider = require(Components.Slider)

local e = React.createElement
local Colors, Fonts, Size = Theme.Colors, Theme.Fonts, Theme.Size

local CLOSE_GLYPH = "✕"
local PANEL_SIZE = UDim2.fromOffset(460, 330)
local PANEL_PADDING = UDim.new(0, 32)
local CONTENT_GAP = UDim.new(0, 22)
local TITLE_TEXT_SIZE = 32
local RESET_BUTTON_SIZE = UDim2.fromOffset(220, 48)
local CENTER = UDim2.fromScale(0.5, 0.5)
local CENTER_ANCHOR = Vector2.new(0.5, 0.5)

export type Props = {
	scale: number, -- the same fit-to-screen scale as the screens behind it
	onClose: () -> (),
}

local function SettingsPanel(props: Props)
	local music, setMusic = React.useState(AudioSettings.get("music"))
	local sfx, setSfx = React.useState(AudioSettings.get("sfx"))

	React.useEffect(function()
		local connection = AudioSettings.changed:Connect(function(channel, volume)
			if channel == "music" then
				setMusic(volume)
			else
				setSfx(volume)
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	return e("TextButton", {
		-- Dimmed backdrop; clicking it closes the panel
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Colors.overlay,
		BackgroundTransparency = Theme.Transparency.overlay,
		[React.Event.Activated] = function()
			props.onClose()
		end,
	}, {
		Panel = e("TextButton", {
			-- A button so clicks on the panel don't fall through to the backdrop
			Text = "",
			AutoButtonColor = false,
			AnchorPoint = CENTER_ANCHOR,
			Position = CENTER,
			Size = PANEL_SIZE,
			BackgroundColor3 = Colors.paperLight,
			BorderSizePixel = 0,
		}, {
			Scale = e("UIScale", { Scale = props.scale }),
			Corner = e("UICorner", { CornerRadius = Size.radius }),
			Stroke = e("UIStroke", {
				Color = Colors.ink,
				Thickness = Size.border,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Padding = e("UIPadding", {
				PaddingLeft = PANEL_PADDING,
				PaddingRight = PANEL_PADDING,
				PaddingTop = PANEL_PADDING,
				PaddingBottom = PANEL_PADDING,
			}),
			Close = e(IconButton, {
				glyph = CLOSE_GLYPH,
				onActivated = props.onClose,
				anchorPoint = Vector2.new(1, 0),
				position = UDim2.fromScale(1, 0),
			}),
			Content = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = CONTENT_GAP }),
				Title = e(Label, {
					text = "Settings",
					font = Fonts.display,
					textSize = TITLE_TEXT_SIZE,
					alignX = Enum.TextXAlignment.Left,
					layoutOrder = 1,
				}),
				Music = e(Slider, {
					label = "Music",
					value = music,
					layoutOrder = 2,
					onChange = function(volume)
						AudioSettings.set("music", volume)
					end,
				}),
				Effects = e(Slider, {
					label = "Sound effects",
					value = sfx,
					layoutOrder = 3,
					onChange = function(volume)
						AudioSettings.set("sfx", volume)
					end,
				}),
				Reset = e(InkButton, {
					text = "Reset to defaults",
					variant = "secondary",
					size = RESET_BUTTON_SIZE,
					layoutOrder = 4,
					onActivated = AudioSettings.resetToDefaults,
				}),
			}),
		}),
	})
end

return SettingsPanel
