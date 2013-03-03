

----------------------------------------------------------------
------------------------- Addendum: ----------------------------

This new modification to the existing sample (https://github.com/erwanb/MachInjectSample)
that was created to use XPC interprocess communication services to communicate between
 the helper apps and the main app.
 
 The problem was that the current method used on (https://github.com/erwanb/MachInjectSample)
 was based on DO (DistributedObjects) to communicate and they didn't work on MacOSX 10.7.5.
 So I updated erwanb's sample and will be offering it as another alternative on mach_inject

----------------------------------------------------------------
How to compile:

git checkout https://github.com/RudyAramayo/MachInjectSample.git (you may have already done this... )
git submodule update --init

Select mach_inject_bundle.xcodeproj from the files selection tableview and set architectures build phase of the mach_inject_bundle target to Native Architecture of the Machine

Select the MachInjectSample project and select the MachInjectSample target... goto the summary pane and  set the deployment target to 10.7







-----------------------------------------------------------------------------
----- Original readme from (https://github.com/erwanb/MachInjectSample) -----



# Welcome To MachInjectSample

**This project has been merged into the [mach_inject](https://github.com/rentzsch/mach_inject) repo.**

MachInjectSample demonstrate the use of mach inject with the new SMJobBless API. By creating a privileged helper tool with the SMJobBless API, we can avoid asking an admin password each time we need to inject code into a process.

## Description of contents

* MachInjectSample: The app.
* Installer: a helper tool (launch-on-demand) for installing mach_inject_bundle.framework (needed by the injector). This avoid the need to create a pkg installer, as the injector need to know the path to mach_inject_bundle at compile time.
* Injector: a helper tool (launch-on-demand daemon) for injecting code in a process.
* Payload: a bundle running inside the process. For demonstration purpose, it just write a message in /var/log/system.log upon loading.

Before testing, you need to code-sign the app, injector and installer with the same certificate.

For more info about the SMJobBless API, [see here](https://developer.apple.com/library/mac/#documentation/ServiceManagement/Reference/ServiceManagement_header_reference/Reference/reference.html#//apple_ref/doc/uid/TP40012447).
For more info on mach_inject, [see here](https://github.com/rentzsch/mach_inject).
