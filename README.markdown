## Description

mach_inject enables you to "inject" code into an arbitrary process on Mac OS X. "Injection" means both 1) copying over the necessary code into the target's address space and 2) remotely creating a new thread to execute the code.

## Must Be This Tall To Ride

Code injection is tricky business. You should be familiar with assembly and runtime calling conventions (ABIs) before using mach_inject.

mach_inject is certainly not bug free and patches are extremely welcome, but the onus is on you when things don't work. Please don't file a bug report stating mach_inject is crashing for you when you try to use it -- you have to be hard-core enough to debug the problem yourself.

## Contributing

Please base your work off the unstable branch. Then submit your Pull Request.

## Version History

### mach_inject 1.3: Nov 08 2016

* [NEW] Add demo project ([Erwan Barrier](https://github.com/rentzsch/mach_inject/pull/3))

* [CHANGE] Switch from `__pthread_set_self` to `_pthread_set_self` on 10.12. ([wzqcongcong](https://github.com/rentzsch/mach_inject/pull/19), rentzsch)

* [FIX] Adjust stack alignment for 10.9 to avoid crash. [issue 5](https://github.com/rentzsch/mach_inject/issues/5) ([Giovanni Donelli](https://github.com/rentzsch/mach_inject/pull/6))

* [FIX] Comment out fprintf for 10.10 and genericize `CODE_SIGN_IDENTITY`. [issue 13](https://github.com/rentzsch/mach_inject/issues/13) ([Rainburst](https://github.com/rentzsch/mach_inject/pull/14))

* [FIX] Add error check. ([Nat!](https://github.com/rentzsch/mach_inject/pull/9))

### mach_inject 1.2: Aug 10 2012

* [NEW] i386 and x86_64 support.

* [CHANGE] Decoupled from mach_star. Most of folks were just using the side or the other of mach_star and this simplifies things (docs, tests).

### mach_star 1.1.1 Dec 18 2005

* General Xcode 2.2 project cleanup. mach_star now includes `.xcodeproj` Xcode 2.2 project files for all of its projects. The old `.xcode` project files have been left in place, but they aren't maintained and may not work. Xcode 2.2 is the recommended mach_star development environment -- Xcode 2.1 had a bug with inter-project dependancies which would cause compilation failure. It works now again in Xcode 2.2.

* Inter-project dependancies should working under Xcode 2.2. Any project you pick, you should just be able to hit the "Build" button and everything should Just Work&trade;.

* There was a stray reference to my username in one of the project, which causes compilation headaches for some folks.

* Bug fix: in `mach_inject_bundle.c`'s `mach_inject_bundle_pid()` I no longer call `CFRelease()` on the framework bundle reference. Reported by Scott Kevill.

* Added some explicit casts now required by gcc 4.

* Added this document.

### mach_star 1.1: Apr 06 2005

* New package added: `mach_inject_bundle`. It has a private subproject: `mach_inject_bundle_stub`. The stub is a generic reusable implementation of the code that gets squirted across the address spaces, which was always tricky to write. `mach_inject_bundle` is an embeddable framework that wraps `mach_inject` and the stub with a simple fire-and-forget API.

* The "DisposeWindowBeeperOverride" example is replaced by "DisposeWindow+Beep".

* The "FinderDisposeWindowBeeperInjector" is replaced by "DisposeWindow+Beep_Injector".

* All the text is now wrapped to 80 chars wide. Done to print nicely in Scott Knaster's [Hacking Mac OS X Tiger](http://www.amazon.com/exec/obidos/ASIN/076458345X). Probably will undo this word-wrap in the future. We all have widescreens nowadays, right? ;-)

* Thanks to Jon Gotow for letting me peek at `SCPatch`, which I used as a guide for `mach_inject_bundle`. It saved me a bunch of time. Also thanks to Bob Ippolito for `CALL_ON_LOAD` assistance.

### mach_star 1.0: Jun 18 2003

* Initial release at MacHack 2003.