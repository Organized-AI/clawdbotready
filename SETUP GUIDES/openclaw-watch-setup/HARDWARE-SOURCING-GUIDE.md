# 🛒 Hardware Sourcing Guide: OpenClaw Watch Experiment

**Last Updated**: 2026-02-20
**Purpose**: Minimum viable hardware for running OpenClaw on Apple Watch

---

## The Compatibility Chain

Every link must hold or the whole thing fails:

```
Apple Watch (watchOS 26) ←→ iPhone (iOS 26) ←→ OpenClaw Gateway (v2026.2.19+)
     │                           │
     │  WCSession relay          │  WebSocket + APNs
     │                           │
     └───── BOTH need to be      └───── iPhone must reach
            compatible with             gateway (LAN, Tailscale,
            each other                  or internet)
```

---

## Apple Watch: What to Buy Secondhand

### Minimum: Apple Watch Series 6 (2020)

watchOS 26 supports Series 6 and later. Anything older is dead for this experiment.

### ❌ DO NOT BUY (cannot run watchOS 26)

| Model | Year | Why Not |
|-------|------|---------|
| Series 5 | 2019 | Dropped from watchOS 11 onward |
| Series 4 | 2018 | Dropped from watchOS 11 onward |
| SE 1st Gen | 2020 | Same S5 chip as Series 5, dropped from watchOS 11 |
| Series 3 or older | ≤2017 | Ancient history |

### ✅ COMPATIBLE MODELS (can run watchOS 26)

| Model | Year | Chip | Display | Always-On | Est. Used Price | Notes |
|-------|------|------|---------|-----------|----------------|-------|
| **Series 6** | 2020 | S6 | 1.57"/1.73" | ✅ | $80–120 | ⚠️ Battery likely degraded (4+ years). Cheapest entry. |
| **SE 2nd Gen** | 2022 | S8 | 1.57"/1.73" | ❌ | $100–140 | ⭐ **BEST VALUE.** Same chip as Series 8, newer battery. No always-on display. |
| **Series 7** | 2021 | S7 | 1.69"/1.90" | ✅ | $120–160 | Bigger screen, crack-resistant front crystal. Good mid-range. |
| **Series 8** | 2022 | S8 | 1.69"/1.90" | ✅ | $140–180 | Crash detection, temperature sensor. Same chip as SE 2. |
| **Ultra** | 2022 | S8 | 1.93" | ✅ | $400–500 | Overkill for this experiment unless you want rugged. |
| **Series 9** | 2023 | S9 | 1.69"/1.90" | ✅ | $200–260 | Double Tap gesture, brighter display, UWB2. |
| **SE 3rd Gen** | 2025 | S10 | 1.57"/1.73" | ❌ | $220–249 | Current gen budget option. Buy new if you want warranty. |
| **Series 10** | 2024 | S10 | 1.74"/1.96" | ✅ | $280–350 | Thinnest Watch, biggest display ever. |

### 🏆 Recommendation for This Experiment

**Apple Watch SE 2nd Generation (2022), GPS-only, 40mm — target $100-120 on eBay/Swappa**

Reasons:
- S8 chip = same silicon as Series 8, plenty of power
- 2022 manufacture = battery health should still be 85%+
- GPS-only = cheapest variant (you don't need cellular for OpenClaw — it relays through iPhone)
- 40mm = cheaper than 44mm, functionally identical for notifications/inbox
- No always-on display = saves battery, which matters for an always-connected OpenClaw relay

If you want always-on display and a slightly bigger screen, bump to **Series 7** ($120-160).

---

## iPhone 11: Compatibility Confirmed

Your existing iPhone 11 works. Here's the full breakdown:

| Requirement | iPhone 11 Status |
|-------------|-----------------|
| iOS 26 | ✅ A13 Bionic is the minimum for iOS 26 |
| watchOS 26 pairing | ✅ iPhone 11 + iOS 26 can pair with Series 6+ |
| APNs push | ✅ Works on all iOS 26 devices |
| WCSession | ✅ Supported |
| OpenClaw iOS app | ✅ Builds from source, no minimum iOS version published |
| RAM (4GB) | ⚠️ Background app survival is less reliable than 6GB+ devices |
| Battery (3110 mAh, 2019) | ⚠️ Likely degraded. Consider battery replacement or keeping it plugged in. |

### If iPhone 11 Proves Unreliable

Upgrade path for better background performance:

| Model | Year | RAM | Chip | Used Price | Why |
|-------|------|-----|------|-----------|-----|
| iPhone 12 mini | 2020 | 4GB | A14 | $150–200 | Marginal upgrade. Still 4GB RAM. |
| **iPhone 13 mini** | 2021 | **6GB** | A15 | $200–250 | **Best upgrade.** 6GB RAM = dramatically better background survival. |
| iPhone SE 3 | 2022 | 4GB | A15 | $180–220 | Fast chip but still 4GB. Not recommended. |
| **iPhone 13** | 2021 | **6GB** | A15 | $220–280 | Same as 13 mini but bigger screen/battery. |

---

## Total Experiment Cost (Minimum)

| Item | Cost | Notes |
|------|------|-------|
| Apple Watch SE 2nd Gen (used) | $100–120 | GPS-only, 40mm |
| iPhone 11 (owned) | $0 | Already have it |
| Apple Developer Account (free tier) | $0 | Personal device signing only |
| Watch band (if not included) | $10–20 | Any compatible 40mm band |
| **Total** | **$110–140** | |

Optional:
| Item | Cost | Notes |
|------|------|-------|
| iPhone 11 battery replacement | $89 | At Apple. Worth it if below 80% health. |
| USB-C to Lightning cable | $10 | For Xcode deployment to iPhone 11 |

---

## Where to Source

- **Swappa** — Best for verified condition/battery health
- **eBay** — Cheapest, but verify seller reputation
- **Facebook Marketplace** — Local pickup, can inspect in person
- **Apple Refurbished** — Not usually available for older models
- **Back Market** — Refurbished with warranty, slightly more expensive

### What to Check When Buying Used Apple Watch

- **Battery Health**: watchOS 9+ shows battery health in Settings → Battery → Battery Health. Ask seller for screenshot. Target 80%+.
- **Activation Lock**: Have seller unpair from their iPhone before buying. If Activation Lock is on, it's a paperweight.
- **Water damage**: Check for liquid indicators (visible in band slot area).
- **Screen condition**: Minor scratches are fine for this experiment. Cracks are not.
- **Model number**: Verify it's actually Series 6+ and not Series 5 marketed as "newer." Check back engravings or Settings → General → About.

---

*This guide is specific to the OpenClaw Watch experiment. For production client deployments, newer hardware is recommended.*
