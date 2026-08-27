# Salt Lake Lawn Field Guide

Mowing, watering, feeding, weeds and overseeding for a **Kentucky bluegrass** lawn in the
**Salt Lake Valley**. Single static page, no build step, no dependencies.

## Where the info comes from

Every turf claim comes from one of six Utah State University Extension documents. Five are
peer-reviewed fact sheets; the sixth is a web checklist and is outranked wherever it conflicts. One
manufacturer source is cited, for controller settings only.

| id | document | published | what it covers |
|----|----------|-----------|----------------|
| `CAL` | [Northern Utah Turfgrass Management Calendar](https://extension.usu.edu/yardandgarden/research/northern-utah-turfgrass-management-calendar) | Dec 2017 | the operations grid, irrigation intervals, aeration specs, seeding windows |
| `IRR` | [Irrigation System Maintenance](https://extension.usu.edu/yardandgarden/research/irrigation-system-maintenance) | Jul 2021 | controllers, head faults, monthly checks, winterization |
| `FERT` | [Lawn Fertilizers for Cool Season Turf](https://extension.usu.edu/yardandgarden/research/lawn-fertilizers-for-cool-season-turf) | Sep 2012 | the fertilization schedule, N sources, the growth curve |
| `INORG` | [Selecting and Using Inorganic Fertilizers](https://extension.usu.edu/yardandgarden/research/selecting-and-using-inorganic-fertilizers) | Dec 2011 | rate math, product analyses, the 1.5 lb burn ceiling, spreaders |
| `BASIC` | [Basic Turfgrass Care](https://extension.usu.edu/yardandgarden/research/basic-turfgrass-care) | Mar 2011 | mowing heights, the 1/3 rule, clippings, dormancy |
| `ALM` | [Gardener's Almanac Monthly Checklist](https://extension.usu.edu/yardandgarden/monthly-tips) | undated | half-month timing, the 60-80°F spray window, final mow |
| `RACHIO` | [Rachio support](https://support.rachio.com/) | n/a | controller feature names and defaults, Water section only |

`CAL` names Salt Lake County in its scope, so the calendar is not being stretched to fit the valley.

## Provenance is a first-class system

Three confidence states, decided before any content was written, plus one source-tier state added
when the Rachio content landed:

- **Sourced**: grey, dotted underline, e.g. `[CAL]`. Links to that document's entry in Provenance.
- **Derived, not sourced**: amber, solid underline. Arithmetic, an inference, or a reading of a
  chart the source does not state outright. Deliberately weaker-looking than a grey marker.
- **Sources disagree**: red, solid underline. Two or more documents give different answers.
- **Manufacturer, not extension**: blue, dashed underline, `[RACHIO]`. A product feature or default.
  Useful for knowing which switch to flip, worth nothing on the question of what a lawn needs.

207 markers on the page: 179 sourced, 7 derived, 11 conflict, 10 product.

The fourth state exists because the conflict policy already ranked manufacturers below extension and
required product-driven claims to be flagged. Folding Rachio into the grey sourced state would have
implied a level of authority it does not have.

### The conflict policy

Written before ingest, applied throughout:

1. Peer-reviewed extension fact sheet beats extension web page beats manufacturer beats forum.
2. Within fact sheets, the more recent and more geographically specific one wins.
3. Where two good sources genuinely disagree, the page says so and gives the reasoning rather than
   quietly picking a winner.
4. No bag label is treated as guidance. Two commercial lawn-care articles were in the source folder
   and are deliberately excluded, cited nowhere. The one manufacturer source, Rachio, is cited only
   for which setting to change, never for what value a lawn needs.

**Four disagreements** are surfaced where they occur: the annual nitrogen rate, the fertilizer
calendar, the final mowing height, and September water volume. The last of these is an internal
error in `ALM`, which contradicts both its own August entry and `CAL`.

### What is not sourced

Collected on the page in one place, under the heading "Not from a source". In short: the catch-cup runtime formula, the
gallons conversion (0.623 gal per sq ft per inch), the month boundaries on the year chart, the
pre-emergent versus overseeding conflict, and three of the four physical tests in troubleshooting.

Three gaps are named rather than invented: this source set says nothing about **soil temperature
thresholds**, nothing specific about **grubs or snow mold**, and nothing about **cultivar selection,
blend ratios or seeding rates**.

## Grass type

Hardcoded to Kentucky bluegrass, cool-season. This is deliberate: hardcoding keeps every number
honest, the same reason the bridgesii guide works.

A **90/10 turf-type tall fescue / KBG overseed changes nothing on the page.** USU treats bluegrass
and the fescues as one category for seeding, overseeding, fertilizing and aeration timing, and the
2-4" mowing band covers both. The data is structured so a grass-type picker could be added later:
`GROWTH`, `MOWTIER`, `MOW`, `WATER`, `WATCH` and `FEEDS` are all plain arrays.

## Triggers are dates here, not soil temperature

The original plan assumed soil temperature at 2" would be the trigger backbone. **None of the six
USU sources mention soil temperature at all.** They give explicit calendar windows for northern
Utah. So the dates are the sourced backbone, and soil temperature appears only as marked-adapted
context with a nudge to verify locally before applying pre-emergent. Quoting a 50-55°F threshold as
sourced would have been fabrication.

## How it works

`index.html` is the whole site. CSS, SVG illustrations and the one script are all inline.

Two dynamic things:

- **The date.** The "Right now" card resolves four independent tracks (mow, water, feed, watch)
  against today, plus a phase headline and progress bar. The year chart marks the current month and
  the water interval table highlights today's row. Re-renders if left open past midnight.
- **Your square footage.** The area calculator persists to `localStorage` under `lawn.sqft` and
  rewrites every product quantity on the page, including the bag table and the feed track. Nothing
  is sent anywhere.

The only external dependency is Google Fonts (Syne, Newsreader, JetBrains Mono). If blocked, the
fallback stacks take over. Light and dark both come from `prefers-color-scheme`; the `[data-theme]`
hooks are in the CSS for a manual toggle later.

## Rachio

The Water section maps USU's guidance onto Rachio's settings. Two of those settings decide whether
everything else is right, and both of Rachio's shipped defaults push the wrong way:

- **Nozzle inches per hour** is a generic estimate per nozzle type. Every Flex Daily runtime derives
  from it, so measure the real rate (catch cups, or a free USU Water Check) and enter it.
- **Root depth** defaults shallow for turf. That contradicts the page's core argument, that mowing at
  3 inches builds deeper roots, and a shallow setting makes Rachio water little and often.

The USU interval table doubles as an audit of Rachio's output: July should land near every 2 days,
September near every 6. If Rachio is watering September on a summer cadence, the zone setup is wrong,
not the weather feed.

## Local preview

```
python3 -m http.server 8000
```

then open `http://localhost:8000`. Opening `index.html` over `file://` works too.

## Tooling

```
scripts/shot.sh <section-id> [width] [height]   # screenshot one section, others hidden,
                                                # reveal animations forced, auto-cropped
scripts/svg.sh  <svg-index> [width] [light|dark] # render one inline SVG standalone,
                                                # resolving CSS custom properties
scripts/probe.sh <png> x,y [x,y ...]            # print RGBA at given pixels
```

`svg.sh` exists because inline SVGs use `var(--token)` fills that `rsvg-convert` cannot resolve on
its own. `probe.sh` is for when eyeballing is not enough, e.g. confirming the four mow-strip tiers
are actually distinguishable.

## Pages setup

Settings > Pages > Source: `Deploy from a branch`, branch `main`, folder `/ (root)`.

`.nojekyll` is there so Pages serves the files as-is instead of running them through Jekyll.

## Written for

The Salt Lake Valley: USU's northern Utah calendar region, roughly **8,100 sq ft** of turf on
in-ground zones run by a **Rachio** controller, alkaline soil around pH 7.5, and a lawn that gets
moderate family use (the 3-feedings-a-year row).

The area calculator defaults to 8,100 and persists per-browser, so any visitor gets their own number
without changing the page.
