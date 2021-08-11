package main

import (
	"fmt"

	"barista.run"
	"barista.run/bar"
	"barista.run/colors"
	"barista.run/format"
	"barista.run/modules/battery"
	"barista.run/modules/clock"
	"barista.run/modules/cpuload"
	"barista.run/modules/cputemp"
	"barista.run/modules/meminfo"
	"barista.run/modules/netinfo"
	"barista.run/modules/netspeed"
	"barista.run/modules/shell"
	"barista.run/modules/sysinfo"
	"barista.run/modules/wlan"
	"barista.run/outputs"
	"github.com/martinlindhe/unit"
)

func main() {
	colors.LoadFromMap(map[string]string{
		"good":     "#0f0",
		"bad":      "#f00",
		"degraded": "#ff0",
	})

	// MPD
	barista.Add(shell.Tail("mpd-status").Output(func(line string) bar.Output {
		color := line[0]
		realLine := line[1:]
		out := outputs.Text(realLine)
		switch color {
		case 'g':
			out.Color(colors.Scheme("good"))
		case 'd':
			out.Color(colors.Scheme("degraded"))
		default:
			out.Color(colors.Scheme("bad"))
		}
		return out
	}))

	// Cafe
	barista.Add(shell.Tail("swayidle-wrapper-status").Output(func(line string) bar.Output {
		color := line[0]
		realLine := line[1:]
		out := outputs.Text(realLine)
		switch color {
		case 'g':
			out.Color(colors.Scheme("good"))
		case 'd':
			out.Color(colors.Scheme("degraded"))
		default:
			out.Color(colors.Scheme("bad"))
		}
		return out
	}))

	// Backlight
	barista.Add(shell.Tail("light-monitor").Output(func(line string) bar.Output {
		return outputs.Textf("BL: %s", line)
	}))

	// Memory
	barista.Add(meminfo.New().Output(func(i meminfo.Info) bar.Output {
		out := outputs.Textf(`%s/%s`,
			format.IBytesize(i["MemTotal"]-i.Available()),
			format.IBytesize(i["MemTotal"]))
		switch {
		case i.AvailFrac() < 0.2:
			out.Color(colors.Scheme("bad"))
		case i.AvailFrac() < 0.33:
			out.Color(colors.Scheme("degraded"))
		}
		return out
	}))

	// Battery
	statusName := map[battery.Status]string{
		battery.Charging:    "CHR",
		battery.Discharging: "BAT",
		battery.NotCharging: "NOT",
		battery.Unknown:     "UNK",
	}
	barista.Add(battery.All().Output(func(b battery.Info) bar.Output {
		if b.Status == battery.Disconnected {
			return nil
		}
		if b.Status == battery.Full {
			return outputs.Text("FULL").Color(colors.Scheme("good"))
		}
		out := outputs.Textf("%s %d%%",
			statusName[b.Status],
			b.RemainingPct())
		if b.Discharging() {
			if b.RemainingPct() <= 20 {
				out.Color(colors.Scheme("bad"))
			}
		}
		if b.Status == battery.Charging {
			out.Color(colors.Scheme("good"))
		}
		return out
	}))

	// Uptime
	barista.Add(sysinfo.New().Output(func(i sysinfo.Info) bar.Output {
		return outputs.Textf("UP: %v", i.Uptime)
	}))

	// Proc Num
	barista.Add(sysinfo.New().Output(func(i sysinfo.Info) bar.Output {
		return outputs.Textf("PS: %d", i.Procs)
	}))

	// Load Average
	barista.Add(cpuload.New().Output(func(l cpuload.LoadAvg) bar.Output {
		return outputs.Textf("LA: %0.2f %0.2f %0.2f", l.Min1(), l.Min5(), l.Min15())
	}))

	// CPU Temp
	barista.Add(cputemp.New().Output(func(t unit.Temperature) bar.Output {
		color := "good"
		if t.Celsius() >= 55 {
			color = "degraded"
		}
		if t.Celsius() >= 65 {
			color = "bad"
		}
		return outputs.Textf("%.0f°C", t.Celsius()).Color(colors.Scheme(color))
	}))

	// Volume
	// For some reason barista's pulseaudio monitor is broken with pipewire-pulse
	barista.Add(shell.Tail("pulse-monitor").Output(func(line string) bar.Output {
		color := line[0]
		realLine := line[1:]
		out := outputs.Text(realLine)
		switch color {
		case 'g':
			out.Color(colors.Scheme("good"))
		case 'd':
			out.Color(colors.Scheme("degraded"))
		default:
			out.Color(colors.Scheme("bad"))
		}
		return out
	}))

	// 802.11
	barista.Add(wlan.Any().Output(func(w wlan.Info) bar.Output {
		if w.Connected() {
			out := fmt.Sprintf("W: (%s on %2.1fG)", w.SSID, w.Frequency.Gigahertz())
			if len(w.IPs) > 0 {
				out += fmt.Sprintf(" %s", w.IPs[0])
			}
			return outputs.Text(out).Color(colors.Scheme("good"))
		}
		return outputs.Text("W: down").Color(colors.Scheme("bad"))
	}))
	barista.Add(netspeed.New("wlan0").Output(func(s netspeed.Speeds) bar.Output {
		if s.Total().BitsPerSecond() == 0 {
			return nil
		}
		return outputs.Textf("W: %s↓ %s↑",
			format.IByterate(s.Rx), format.IByterate(s.Tx))
	}))

	// Ethernet
	barista.Add(netinfo.Prefix("e").Output(func(s netinfo.State) bar.Output {
		if s.Connected() {
			ip := "<no ip>"
			if len(s.IPs) > 0 {
				ip = s.IPs[0].String()
			}
			return outputs.Textf("E: %s", ip).Color(colors.Scheme("good"))
		}
		return outputs.Text("E: down").Color(colors.Scheme("bad"))
	}))
	barista.Add(netspeed.New("eth0").Output(func(s netspeed.Speeds) bar.Output {
		if s.Total().BitsPerSecond() == 0 {
			return nil
		}
		return outputs.Textf("E: %s↓ %s↑",
			format.IByterate(s.Rx), format.IByterate(s.Tx))
	}))

	// Time
	barista.Add(clock.Local().OutputFormat("2006-01-02 15:04:05 -0700"))

	barista.SuppressSignals(true)
	panic(barista.Run())
}
