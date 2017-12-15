Setup
===

 1. Run `vagrant up` and wait for provisioning to finish

 2. Log in with password: `vagrant`

 3. Open _Programs and Features_ -> _Microsoft Visual Studio Community 2015_ ->
    _Change_. Click _Modify_, _Add or remove components_ and add the following
    components:

    - Programming Languages -> Visual C++ -> Common Tools for Visual C++ 2015
    - Windows and Web Development -> ClickOnce Publishing Tools
    - Windows and Web Development -> Universal Windows App Development Tools ->
      Windows 10 SDK

 4. Open command prompt as administrator

 5. Run `Z:\vagrant\windows\install-qt.bat`. Accept all the defaults, except for
    the components selection page. Deselect all and then select the following
    components:

    - Qt -> Qt 5.9.3 -> msvc2015 32-bit

 6. Run `Z:\vagrant\windows\install-pyotherside.bat`

 7. Run `choco install -y git`. This should ideally be done by the provisioning
    script, but it fails for some reason.
