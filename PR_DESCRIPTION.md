Title: fix(tab-colorpicker-update): fix tab visibility, colorpicker parsing, notify size, image & background support

Summary:
- Fix tabs so each tab keeps its content container (Visible toggling) to preserve events/state.
- Improve ColorPicker parsing: accept #RGB and #RRGGBB, clamp RGB, manage ActiveColorPicker properly.
- Increase notification close button size to 32px and adjust positioning/animation.
- Add Image/Img helper to create Image elements (supports numeric id and full asset strings).
- Add BackgroundId option for CreateWindow to set ImageLabel as background when provided.
- Remove redundant outer frames and tidy UI spacing/rounding.
- Add 4 new themes: Solar, Vapor, Orchid, Nightfall.
- Add example usage file.

Files changed:
- Simple lib updated.lua
- Theme extra.lua
- Example.lua

Notes for testing:
- Place module in an appropriate location (ModuleScript) and require it from a LocalScript.
- Test CreateWindow with BackgroundId numeric and string forms.
- Test Tab switching preserves control state/event handlers.
- Test ColorPicker by inputting #f09 and #ff0099 into the hex box.
- Test notifications for new close button size/position.
