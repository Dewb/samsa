-- samsa.lua
-- by @dewb
-- 4/7/2025
--
-- transform the arc into a 16n; sixteen high-resolution MIDI CC faders.
-- small gestures make small changes, big gestures make big changes.
-- press key to change pages.
-- supports LED feedback from host to display automation, etc.
--
-- todo:
--    * enable use of 16n editor: send/receive 16n config sysex
--    * save config to flash
--    * implement acceleration instead of cubic delta?

faders = {
    {{},{},{},{}}, {{},{},{},{}}, {{},{},{},{}}, {{},{},{},{}},
}

function init_faders()
    faders[1][1] = {cc=0, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[1][2] = {cc=1, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[1][3] = {cc=2, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[1][4] = {cc=3, ch=1, hires=true, value=0, msb=0, lsb=0}

    faders[2][1] = {cc=4, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[2][2] = {cc=5, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[2][3] = {cc=6, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[2][4] = {cc=7, ch=1, hires=true, value=0, msb=0, lsb=0}

    faders[3][1] = {cc=8, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[3][2] = {cc=9, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[3][3] = {cc=10, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[3][4] = {cc=11, ch=1, hires=true, value=0, msb=0, lsb=0}

    faders[4][1] = {cc=12, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[4][2] = {cc=13, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[4][3] = {cc=14, ch=1, hires=true, value=0, msb=0, lsb=0}
    faders[4][4] = {cc=15, ch=1, hires=true, value=0, msb=0, lsb=0}
end

init_faders()

page = 1
dirty = true
indicate_page = false

meta = {
    script = "samsa",
    version = "0.1",
}

function init()
    print("🐞🐞🐞🐞 samsa 🐞🐞🐞🐞")
    print("")
    print("one morning, as the arc was waking up from anxious dreams, it discovered it had been changed into a 16n.")

    redraw_metro = metro.new(redraw, 33, -1)
end

function arc_key(z)
    if z == 1 then
        page = wrap(page + 1, 1, 4)
        indicate_page = true
    else
        indicate_page = false
    end
    dirty = true
end

function redraw()
    if dirty == true then
        if indicate_page == true then
            for n = 1, 4 do
                arc_led_all(n, n == page and 5 or 0)
            end
        else
            redraw_page(page)
        end
        arc_refresh()
        dirty = false
    end
end

function redraw_page(p)
    for n = 1, 4 do
        arc_led_all(n, 0)

        local hi = ((faders[p][n].msb >> 1) & 0x3F) + 1
        local lo = (faders[p][n].lsb & 0x3F) + 1
        local med = ((faders[p][n].msb << 1) & 0x02) | ((faders[p][n].lsb >> 6) & 0x01)

        -- gradient to show full range with top 6 bits
        arc_led_range(n, 1, hi, 1, 8)
        -- indicator at top of range to glow middle 2 bits
        arc_led_single(n, hi, med)
        -- fast indicator showing low 6 bits
        arc_led_single(n, lo, 15)
    end
end

function arc(n, d)
    if indicate_page == true then return end
    local factor = 0.00003125 * 0.5
    faders[page][n].value = clamp(faders[page][n].value + (d * d * d) * factor, 0, 1.0)
    local v = round(faders[page][n].value * 16383)
    faders[page][n].msb = (v >> 7) & 0x7F
    faders[page][n].lsb = (v) & 0x7F
    dirty = true
    send_midi_for_fader(page, n)
end

function send_midi_for_fader(p, n)
    midi_cc(faders[p][n].cc, faders[p][n].msb, faders[p][n].ch)
    if faders[p][n].hires then
        midi_cc(faders[p][n].cc + 32, faders[p][n].lsb, faders[p][n].ch)
    end
end

function midi_rx(ch, status, data1, data2)
    --ps("received %d %d %d on ch %d", status, data1, data2, ch)
    if status == 176 then -- continuous controller
        local x, y, f
        for x = 1, 4 do
            for y = 1, 4 do
                f = faders[x][y]
                if f.cc == data1 and f.msb ~= data2 then
                    f.msb = data2
                    f.value = ((f.msb << 7) + f.lsb) / 16383.0
                    dirty = true
                elseif f.hires == true and f.cc + 32 == data1 and f.lsb ~= data2 then
                    f.lsb = data2
                    f.value = ((f.msb << 7) + f.lsb) / 16383.0
                    dirty = true
                end
            end
        end
    end
end

-- arc drawing utility functions

function arc_led_range(n, first, last, startval, endval)
    local v
    local f = wrap(first, 1, 64)
    local l = wrap(last, 1, 64)
    for i = f, l do
        v = round(linlin(f, l, startval, endval, i))
        arc_led(n, wrap(i - 31, 1, 64), v)
    end
end

function arc_led_single(n, pos, val)
  arc_led(n, wrap(pos - 31, 1, 64), wrap(val, 0, 15))
end

init()