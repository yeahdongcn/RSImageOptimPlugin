#RSImageOptimPlugin

[![Total views](https://sourcegraph.com/api/repos/github.com/yeahdongcn/RSImageOptimPlugin/counters/views.png)](https://sourcegraph.com/github.com/yeahdongcn/RSImageOptimPlugin)
[![Views in the last 24 hours](https://sourcegraph.com/api/repos/github.com/yeahdongcn/RSImageOptimPlugin/counters/views-24h.png)](https://sourcegraph.com/github.com/yeahdongcn/RSImageOptimPlugin)

Xcode plugin to optimize images using [ImageOptim](https://github.com/pornel/ImageOptim).

![menu](https://raw.githubusercontent.com/yeahdongcn/RSImageOptimPlugin/master/RSImageOptimPlugin-screenshot@2x.png)

![ImageOptim](https://raw.githubusercontent.com/yeahdongcn/RSImageOptimPlugin/master/ImageOptim-screenshot@2x.png)

##TODO

##Requirements

Xcode 5.0+ on OS X 10.9+.

##Installation

#### [Alcatraz](https://github.com/supermarin/Alcatraz)

* [Alcatraz](https://github.com/supermarin/Alcatraz) is the recommended method of installing this plugin.
* Relaunch Xcode.

#### Build from Source

* Build the Xcode project. The plug-in will automatically be installed in `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`. 
* Relaunch Xcode.

To uninstall, just remove the plugin from `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins` and restart Xcode.

## How does it work?

All the commands are laid at the bottom of the menu `File`.

* Use the menu `ImageOptim` to optimize all images in the workspace immediately.
* Use the menu `Enable Auto ImageOptim` to toggle whether automatic optimization should be enabled. Once this has been enabled, `ImageOptim` will be launched automatically to optimize the new added image files. 

##Thanks

Thanks [Pornel](https://github.com/pornel)'s open source GUI image optimizer for Mac [ImageOptim](https://imageoptim.com).

##License

    The MIT License (MIT)

    Copyright (c) 2012-2014 P.D.Q.

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
    the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
