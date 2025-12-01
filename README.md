<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".assets/morpheus_wordmark_white.svg"/>
    <img width=512 src=".assets/morpheus_wordmark.svg" alt="Morpheus Logo"/>
  </picture>
</p>

> _You take the blue pill: the story ends, you wake up in your bed and believe whatever you want to believe. You take the red pill: you stay in Wonderland, and I show you how deep the rabbit hole goes._

_**Morpheus**_ is a tool used to enable features bound to the Redpill feature lockout system and its four lockdown tiers on compatible Windows 8 development builds compiled between Milestone 1 up through Milestone 3/Developer Preview, in addition to a limited number of Consumer Preview builds (up to ~8123).

Unlike other previous approaches made to enable Redpill features, Morpheus leverages the pre-existing Redpill license tokens sourced from the Windows 8 Developer Preview (`WINMAIN_WIN8M3` 8102.101); its approach does not disable the Software Protection Platform (SPP), the Windows service responsible for managing the operating system's activation state.

<p align="center">
  <picture>
    <img width=512 src=".assets/morpheus_demo1.png" alt="Morpheus Demo Screenshot - Redpill licensing tier selection"/>
  </picture>
</p>

<p align="center">
  <picture>
    <img src=".assets/morpheus_overview_diagram.png" alt="Redpill Conversion Diagram"/>
  </picture>
</p>

## Usage
Run Morpheus on a Windows 8 build with production-signed SPP certificate chains. You can determine whether a build is using production signing by checking whether the SPP Trusted Store directory (`Windows\System32\spp\store`) exists in the OS installation. Builds with test-signed certificate chains are easily distinguished from production-signed chains if the SPP store directory has the `_test` suffix in its name; Morpheus will not run if this is the case.

Morpheus supports Windows 8 builds 7779 through 8123, through your mileage may vary between different milestones. Morpheus will refuse to run on the following Windows 8 builds, in particular:
* `WINMAIN` 8020 x86/amd64
* `FBL_EEAP` builds 8049 and later
* Any `WINMAIN_WIN8M3_EEAP` build

## Credits
Kudos to the following for their tools and help:
* gus33000 and casm for making Redlock, the tool used to drop in the Redpill payload
* The folks at MAS for developing [TSForge](https://github.com/massgravel/TSForge)
	* Special thanks to @WitherOrNot for assisting in debugging an astoundingly stupid SPP bug that prevented the other three Redpill licensing tiers from activating
* NirSoft for their AdvancedRun tool (used to elevate Redlock to the `TrustedInstaller` account)

## Screenshots
<p align="center">
  <picture>
    <img width=384 src=".assets/morpheus_demo2.png" alt="Morpheus Demo Screenshot - Redpill Tier 3"/>
  </picture>
  <picture>
    <img width=384 src=".assets/morpheus_demo3.png" alt="Morpheus Demo Screenshot - Metro OOBE and SPPSvc running at once"/>
  </picture>
</p>