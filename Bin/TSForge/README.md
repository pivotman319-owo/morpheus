# TSforge

By WitherOrNot & asdcorp

## About

A collection of activation/evaluation extension methods for Windows Vista through 11.

Note: We provide no support for direct use of this tool. The only supported implementation of the methods presented here is in [Microsoft Activation Scripts](https://massgrave.dev).

Included methods and tools:
- ZeroCID - Permanent activation until reinstall/feature upgrade
- KMS4k - Offline KMS activation for over 4000 years
- AVMA4k - Offline AVMA activation for over 4000 years (Server 2012 R2+ only)
- Reset Rearm Count - Reset rearm counter for infinite evaluation
- Reset Eval Period - Reset evaluation period for infinite evaluation
- Dump/Load Trusted Store - Dump and load trusted store data
- Delete Unique ID - Delete a product key's unique ID to prevent online validation
- Install Generated Product Key - Install generated product key data for any product
- KMS Charger - Charge an existing KMS server to allow immediate use for activation
- Clear Tamper State - Clear the tamper state set due to store corruption or deletion
- Remove Evaluation Key Lock - Remove the product key change lock set for evaluation product keys
- Set IID Parameters - Set parameters for IID independently of installed key

## Usage

```
Usage: TSforge [/dump <filePath> (<encrFilePath>)] [/load <filePath>] [/kms4k] [/avma4k] [/zcid] [/rtmr] [/duid] [/igpk] [/kmsc] [/ctpr] [/revl] [/siid <5/9> <group> <serial> <security>] [/prod] [/test] [<activation id>] [/ver <version override>]
Options:
        /dump <filePath> (<encrFilePath>)         Dump and decrypt the physical store to the specified path.
        /load <filePath>                          Load and re-encrypt the physical store from the specified path.
        /kms4k                                    Activate using KMS4k. Only supports KMS-activatable editions.
        /avma4k                                   Activate using AVMA4k. Only supports Windows Server 2012 R2+.
        /zcid                                     Activate using ZeroCID. Only supports phone-activatable editions.
        /rtmr                                     Reset grace/evaluation period timers.
        /rrmc                                     Reset the rearm count.
        /duid                                     Delete product key Unique ID used in online key validation.
        /igpk                                     Install auto-generated/fake product key according to the specified Activation ID
        /kmsc                                     Reset the charged count on the local KMS server to 25. Requires an activated KMS host.
        /ctpr                                     Remove the tamper flags that get set in the physical store when sppsvc detects an attempt to tamper with it.
        /revl                                     Remove the key change lock in evaluation edition store.
        /siid <5/9> <group> <serial> <security>   Set Installation ID parameters independently of installed key. 5/9 argument specifies PKEY200[5/9] key algorithm.
        /prod                                     Use SPP production key.
        /test                                     Use SPP test key.
        /ver <version>                            Override the detected version. Available versions: vista, 7, 8, blue, modern.
        <activation id>                           A specific activation ID. Useful if you want to activate specific addons like ESU.
        /?                                        Display this help message.
```

## FAQ

### How does this work?

This tool manipulates data stored in a file known as the "physical store", which is used by Windows to store critical activation data, including expiry timers and the HWIDs bound to each license. Thanks to our reverse-engineering efforts, we are able to insert our own data into the physical store, allowing us to add custom activation data for any product managed by Windows' Software Protection Platform. The data in the physical store is also known as the "trusted store", leading to the name "TSforge".

### What advantages does this method have over other activation methods?

TSforge offers the most advantages for activating older Windows versions, such as Windows 7 through 8.1, as it can permanently activate any edition of these versions without modifications to the boot process or Windows system executables. TSforge is also the only public activator capable of activating any Windows addon, making it useful for users who wish to activate ESU licenses. Additionally, TSforge is the only public activator to offer hardware-invariant activation without any persistent network connections, added services/tasks, or injected DLLs.

TLDR: You should only use TSforge if you are using an old Windows release or if you want to activate addons such as ESU to extend the support end date.

### What are the downsides?

For Windows 10 and 11, it is recommended to use the HWID method to activate Windows. TSforge is both less reliable and lacks features that HWID offers, such as the ability to survive feature upgrades and complete OS reinstalls. For Windows 7 through 8.1, there are no notable downsides.

### Do any of the methods here require internet?

No, none of the methods presented here require connecting to the internet in order to function. Everything is done locally.

### How can I install specific licenses without having to install the corresponding product key?

You can use the `/igpk` switch in TSforge in order to install licenses by only using an Activation ID. You can get a list of all installable licenses and their Activation ID's by running `slmgr /dlv all`. You can click into the popup window and press CTRL + C to copy all of the information. Once you have found your desired licenses' Activation ID, run `/igpk` like so: `TSforge.exe /igpk <activation id>`.

### How do I activate a KMS Host server?

You can use the `/igpk` and `/zcid` options with the activation ID of the KMS Host SKU to be activated. You can then use the `/kmsc` option with this activation ID to charge the KMS server with 25 clients. Please note that KMS servers will maintain their client counts for a maximum of 30 days.

### What features are implemented in Windows Vista?

The following options are implemented:

 - `/dump`
 - `/load`
 - `/zcid`
 - `/kms4k`
 - `/rtmr`
 - `/rrmc`
 - `/kmsc`
 - `/ctpr`

The following options are NOT implemented:

 - `/duid` - Key Unique ID is not removable from Vista physical store
 - `/igpk` - Product key data is derived directly from the key string, preventing forgery
 - `/siid` - IID is also derived directly from the key string
 - `/revl` - Eval key lock is not present on Vista

 Effectively, this means that a product key must be provided to activate a given SKU. Additionally, ZeroCID on Vista/Server 2008 lacks protection against deactivation due to the WGA update KB929391, though this update is no longer offered via Windows Update.

### How do I prevent de-activation due to WAT on Windows 7?

If generic keys are installed, you need to run `TSforge.exe /duid` to remove the product key's unique ID. This will prevent WAT from verifying the key online. Installing a fake product key with `TSforge.exe /igpk <activation id>` will have an equivalent effect. Alternatively, you can use a non-generic key to bypass this check, though many publicly available keys are blocked by WAT.

### AVMA4k doesn't work in my virtual machine, why?

Windows doesn't support AVMA activation under VM software that fails to provide [Hyper-V Enlightenments](https://www.qemu.org/docs/master/system/i386/hyperv.html). This primarily means that AVMA4k is only supported on VMs running under a [correctly configured QEMU instance](https://blog.wikichoon.com/2014/07/enabling-hyper-v-enlightenments-with-kvm.html) or Hyper-V. If your VM's activation status is `Notification` with the status code `0xC004FD01` after using AVMA4k, you will need to use another activation method.

### Does TSforge support beta versions of Windows?

It can, though we do not provide official support for these versions. TSforge works on most insider/beta builds of Windows past Windows 8.1. Beta builds prior to build 9600 are likely to face issues, as the internal data formats used by SPP were constantly changing during this period of development. Builds with similar licensing behavior to retail versions are the most likely to work with the current TSforge codebase. For other builds, you may need to manually edit the source code of LibTSforge to get it to work.

### How do I remove this activation?

Run [Microsoft Activation Scripts](https://massgrave.dev), select `Troubleshoot` > `Fix Licensing`. This will reset the physical store and revert any changes made by TSforge.

### Can Microsoft patch this?

Yes, albeit with some amount of difficulty.

### Will they?

Probably not. If they do, please tell us so we can laugh to ourselves like a bunch of lunatics for the rest of the week.

## Build instructions

1. Download [.NET SDK 9.0.2](https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-9.0.200-windows-x64-binaries)
2. Extract the contents of the downloaded archive to `C:\dotnet-sdk-9.0.200-win-x64`
3. Open command prompt in the directory where `TSforge.sln` can be found
4. Run `C:\dotnet-sdk-9.0.200-win-x64\dotnet.exe build -c Release TSforge.sln`
5. Built binaries can be found in `TSforgeCLI\bin\Release\net35`

## Credits

### Core Research and Development

- WitherOrNot - Lead tool development, reverse engineering, testing
- asdcorp - Initial demonstrations, reverse engineering, tool development, testing
- abbodi1406 - Reverse engineering, development, testing
- Lyssa - Reverse engineering, tool development, testing

### Other Contributions

- Emma (IPG) - Vista SPSys IOCTLs and physical store format
- May - Code formatting, build setup

### Special Thanks

- BetaWiki - Documenting leaked beta builds used for reverse engineering
- Rairii - Assistance with initial reverse engineering efforts
- Microsoft - A fun challenge

## License

The project is licensed under the terms of the [GNU General Public License v3.0](LICENSE).