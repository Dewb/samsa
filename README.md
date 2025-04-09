# samsa

script for iii arc

```lua
-- samsa.lua
-- by @dewb
-- 4/7/2025
--
-- transform the arc into a 16n; sixteen high-resolution MIDI CC faders.
-- small gestures make small changes, big gestures make big changes.
-- press key to cycle through four pages.
-- supports LED feedback from host to display automation, etc.
--
-- todo:
--    * enable use of 16n editor: send/receive 16n config sysex
--    * save config to flash
--    * implement acceleration instead of cubic delta?
```

# how to use

1. connect arc in iii mode
2. from this directory, run `diii` ([instructions here](https://github.com/monome/iii?tab=readme-ov-file#diii))
2. at the diii console, enter `u samsa.lua`